ffi.cdef[[
    int VirtualFree(void* lpAddress, unsigned long dwSize, unsigned long dwFreeType);
    void* VirtualAlloc(void* lpAddress, unsigned long dwSize, unsigned long  flAllocationType, unsigned long flProtect);
    int VirtualProtect(void* lpAddress, unsigned long dwSize, unsigned long flNewProtect, unsigned long* lpflOldProtect);
]]

local ffi_lib = {

    copy = function(dst, src, len)
        return ffi.copy(ffi.cast("void*", dst), ffi.cast("const void*", src), len)
    end,

    virtual_protect = function(lpAddress, dwSize, flNewProtect, lpflOldProtect)
        return ffi.C.VirtualProtect(ffi.cast("void*", lpAddress), dwSize, flNewProtect, lpflOldProtect)
    end,

    virtual_alloc = function(lpAddress, dwSize, flAllocationType, flProtect)
        local alloc = ffi.C.VirtualAlloc(lpAddress, dwSize, flAllocationType, flProtect)
        return ffi.cast("intptr_t", alloc)
    end,

}

local vmt_hook = {
    buffer = {},
    hooks = {}
}

local create_vmt_hook = function(method)
    local org_func = {}
    local new_hook = {}
    new_hook.this = ffi.cast("intptr_t**", method)[0]
    local old_prot = ffi.new("unsigned long[1]")
    local virtual_table = ffi.cast("intptr_t**", method)[0]

    new_hook.hookMethod = function (cast, func, method)
        org_func[method] = virtual_table[method]
        ffi_lib.virtual_protect(virtual_table + method, 4, 0x4, old_prot)
        virtual_table[method] = ffi.cast("intptr_t", ffi.cast(cast, func))
        ffi_lib.virtual_protect(virtual_table + method, 4, old_prot[0], old_prot)
        return ffi.cast(cast, org_func[method])
    end

    new_hook.unHookMethod = function (method)
        ffi_lib.virtual_protect(virtual_table + method, 4, 0x4, old_prot)
        local alloc_addr = ffi_lib.virtual_alloc(nil, 5, 0x1000, 0x40)
        local trampoline_bytes = ffi.new("uint8_t[?]", 5, 0x90)
        trampoline_bytes[0] = 0xE9
        ffi.cast("int32_t*", trampoline_bytes + 1)[0] = org_func[method] - tonumber(alloc_addr) - 5
        ffi_lib.copy(alloc_addr, trampoline_bytes, 5)
        virtual_table[method] = ffi.cast("intptr_t", alloc_addr)
        ffi_lib.virtual_protect(virtual_table + method, 4, old_prot[0], old_prot)
        org_func[method] = nil
    end

    new_hook.unHookAll = function ()
        for method, func in pairs(org_func) do
            new_hook.unHookMethod(method)
        end
    end

    table.insert(vmt_hook.hooks, new_hook.unHookAll)
    return new_hook
end

local hook_fn = {}

local VClient018_interface = utils.create_interface("client.dll", "VClient018")

local function framestage(curStage)
    hook_fn.hook_framestage(curStage)
end

events["render"]:set(function ()
    local local_player = entity.get_local_player()

    if not local_player or not local_player:is_alive() or not globals.is_in_game or not globals.is_connected then
        return false
    end

    if not hook_fn.hook_framestage then
        hook_fn.hook_framestage = create_vmt_hook(VClient018_interface).hookMethod("void(__stdcall*)(int Stage)", framestage, 37)
    end
end)

events["shutdown"]:set(function ()
    if #vmt_hook.buffer > 0 then
        for _, buffer in pairs(vmt_hook.buffer) do
            buffer()
        end
    end

    if #vmt_hook.hooks > 0 then
        for _, hook in pairs(vmt_hook.hooks) do
            hook()
        end
    end
end)
