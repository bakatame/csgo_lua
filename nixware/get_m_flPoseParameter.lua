local bind_argument = function(fn, arg)
    return function(...)
        return fn(arg, ...)
    end
end

local get_vfunc = function(module, interface, index, type)
    local success, instance = pcall(se.create_interface, module, interface)
    if not success or instance == nil then
        error(("reason: interface(module: %s, interface: %s"):format(module, interface))
    end
    local addr = ffi.cast("void***", instance)
    return ffi.cast(ffi.typeof(type), addr[0][index]), addr
end

local get_client_entity_list = bind_argument(get_vfunc("client.dll", "VClientEntityList003", 3, "void*(__thiscall*)(void*, int)"))

local get_client_entity = function(entity)
    local pointer = ffi.cast("char*", entity[0])
    if pointer and pointer ~= ffi.NULL then return pointer end
    local client_entity = get_client_entity_list(entity:get_index())
    if client_entity and client_entity ~= ffi.NULL then return ffi.cast(typedef, client_entity) end
    return false
end

local m_flPoseParameter = function(index)
    local player_index = get_client_entity(index)
    -- prop name/class = https://github.com/L33T/CSGO-Reflection/blob/master/DT_BaseAnimating.txt
    -- prop type = https://gamesensical.gitbook.io/docs/developers/netprops/baseentities/cbaseanimating
    local offset = se.get_netvar("DT_BaseAnimating", "m_flPoseParameter")
    return ffi.cast(ffi.typeof("float*"), player_index + offset)
end
