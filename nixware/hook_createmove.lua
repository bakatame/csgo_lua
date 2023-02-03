ffi.cdef [[
    int VirtualProtect(void* lpAddress, unsigned long dwSize, unsigned long flNewProtect, unsigned long* lpflOldProtect);

    typedef struct {
        float x, y, z;
    } vec3_t;

    typedef struct
    {
        void* vmt;
        int commandNumber;
        int tickCount;
        vec3_t viewangles;
        vec3_t aimDirection;
        float forwardMove;
        float sideMove;
        float upMove;
        int buttons;
        char impulse;
        int weaponSelect;
        int weaponSubType;
        int randomSeed;
        short mouseDeltaX;
        short mouseDeltaY;
        bool hasBeenPredicted;
        vec3_t  headAngles;
        vec3_t headOffset;
    
    } UserCmd;

]]

-- Hooking library
local hook = {hooks = {}}
local hook_fn = {}
function hook.new(cast, callback, hook_addr, size)
    local size = size or 5
    local new_hook = {}
    local detour_addr = tonumber(ffi.cast('intptr_t', ffi.cast('void*', ffi.cast(cast, callback))))
    local void_addr = ffi.cast('void*', hook_addr)
    local old_prot = ffi.new('unsigned long[1]')
    local org_bytes = ffi.new('uint8_t[?]', size)
    ffi.copy(org_bytes, void_addr, size)
    local hook_bytes = ffi.new('uint8_t[?]', size, 0x90)
    hook_bytes[0] = 0xE9
    ffi.cast('uint32_t*', hook_bytes + 1)[0] = detour_addr - hook_addr - 5
    new_hook.call = ffi.cast(cast, hook_addr)
    new_hook.status = false
    local function set_status(bool)
        new_hook.status = bool
        ffi.C.VirtualProtect(void_addr, size, 0x40, old_prot)
        ffi.copy(void_addr, bool and hook_bytes or org_bytes, size)
        ffi.C.VirtualProtect(void_addr, size, old_prot[0], old_prot)
    end
    new_hook.stop = function() set_status(false) end
    new_hook.start = function() set_status(true) end
    new_hook.start()
    table.insert(hook.hooks, new_hook)
    return setmetatable(new_hook, {
        __call = function(self, ...)
            self.stop()
            local res = self.call(...)
            self.start()
            return res
        end
    })
end

local client_dll = ffi.cast("uintptr_t**", se.create_interface("client.dll", "VClient018"))[0]
local client_mode = ffi.cast("void***", client_dll[10] + ffi.cast("unsigned long", 0x5))[0][0]
local create_move_addr = ffi.cast("int**", client_mode)[0][24]

local function creave_move(this, float, cmd)
    cmd.viewangles.x = 89
    return false
end

local function on_paint()
    if not engine.is_in_game() or not engine.is_connected() then return end

    if not hook_fn.hook_createmove then
        hook_fn.hook_createmove = hook.new("void(__thiscall*)(void*, float, UserCmd*)", creave_move, create_move_addr, nil)
    end
    
end
client.register_callback("paint", on_paint)

client.register_callback('unload', function(scr)
    for i, hook in ipairs(hook.hooks) do
         if hook.status then
            hook.stop()
        end
    end
end)
