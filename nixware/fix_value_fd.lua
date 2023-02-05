local my_keybind = ui.add_key_bind("Fakeduck bind", "valve_fakeduck_bind", 0, 1)
local max_choke = ui.add_slider_int("Max choke", "valve_fakeduck_max_choke", 1, 6, 5)
local min_height = ui.add_slider_float("Min height", "valve_fakeduck_min_height", 0, 1, 0.571)

-- Hooking library
local hook = {hooks = {}}
client.register_callback('unload', function(scr)
    for i, hook in ipairs(hook.hooks) do
         if hook.status then
            hook.stop()
        end
    end
end)
ffi.cdef [[
    int VirtualProtect(void* lpAddress, unsigned long dwSize, unsigned long flNewProtect, unsigned long* lpflOldProtect);
    typedef void PVOID;

    typedef struct {
        float x, y, z;
    } vec3_t;

    typedef struct
    {
        int   x;                  //0x0000 
	    int   x_old;              //0x0004 
	    int   y;                  //0x0008 
	    int   y_old;              //0x000C 
	    int   width;              //0x0010 
	    int   width_old;          //0x0014 
	    int   height;             //0x0018 
	    int   height_old;         //0x001C 
	    char      pad_0x0020[0x90];   //0x0020
	    float     fov;                //0x00B0 
	    float     viewmodel_fov;      //0x00B4 
	    vec3_t    origin;             //0x00B8 
	    vec3_t    angles;             //0x00C4 
	    char      pad_0x00D0[0x7C];   //0x00D0
    } CViewSetup;
]]

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
-- Hooking library

local m_vecOrigin = se.get_netvar("DT_BaseEntity", "m_vecOrigin")
local m_fFlags = se.get_netvar("DT_BasePlayer", "m_fFlags")
local m_flDuckAmount = se.get_netvar("DT_BasePlayer", "m_flDuckAmount")

local fakeducking = false

function hooked_override_view(ecx, edx, psetup)
    if fakeducking then
        local lp = entitylist.get_local_player()
        if lp:is_alive() then
            local origin = lp:get_prop_vector(m_vecOrigin)
            local new_origin = vec3_t.new(origin.x, origin.y, origin.z + 64)
            -- error fraction value
            -- local fraction, ent_index = trace.line(0, 0, origin, new_origin)
            -- psetup.origin.z = origin.z + (60.0 * fraction)
            psetup.origin.z = origin.z + (60.0)
        end
    end

    override_view_hook(ecx, edx, psetup)
end

local client_dll = ffi.cast("uintptr_t**", se.create_interface("client.dll", "VClient018"))[0]
local client_mode = ffi.cast("void***", client_dll[10] + ffi.cast("unsigned long", 0x5))[0][0]
local override_view = ffi.cast("int**", client_mode)[0][18]
override_view_hook = nil

local fakelag_enable = ui.get_check_box("antihit_fakelag_enable")
local fakelag_backup = fakelag_enable:get_value()
local sended = 0

local function on_create_move(cmd)
    local lp = entitylist.get_local_player()

    local fakelag_limit = max_choke:get_value()
    if bit32.band(lp:get_prop_int(m_fFlags), 1) ~= 0 and my_keybind:is_active() then
        fakelag_enable:set_value(false)
        cmd.buttons = bit32.bor(cmd.buttons, 4194304)

        local choked = clientstate.get_choked_commands()
        cmd.send_packet = choked >= fakelag_limit

        if cmd.send_packet then
            sended = 0
        else
            sended = sended + 1
        end

        local duck_amount = lp:get_prop_float(m_flDuckAmount)

        if sended < 1 or sended == fakelag_limit or duck_amount < min_height:get_value() then
            cmd.buttons = bit32.bor(cmd.buttons, 4)
        else
            cmd.buttons = bit32.band(cmd.buttons, bit32.bnot(4))
        end

        fakeducking = true
    elseif fakeducking then
        fakelag_enable:set_value(fakelag_backup)
        sended = 0
        fakeducking = false
    else
        fakelag_backup = fakelag_enable:get_value()
    end
end

local function on_paint()
    if engine.is_in_game() and engine.is_connected() and not override_view_hook then
        override_view_hook = hook.new("void(__fastcall*)(void*, void*, CViewSetup*)", hooked_override_view, override_view, nil)
    end
end

client.register_callback("create_move", on_create_move)
client.register_callback("paint", on_paint)
