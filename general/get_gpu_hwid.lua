local ffi = require("ffi")

ffi.cdef[[

    typedef unsigned long DWORD;
    typedef int BOOL;
    typedef const char* LPCSTR;
    
    typedef struct {
        DWORD  cb;
        char   DeviceName[32];
        char   DeviceString[128];
        DWORD  StateFlags;
        char   DeviceID[128];
        char   DeviceKey[128];
    } DISPLAY_DEVICEA;

    BOOL EnumDisplayDevicesA(
        LPCSTR lpDevice,
        DWORD iDevNum,
        DISPLAY_DEVICEA *lpDisplayDevice,
        DWORD dwFlags
    );

    DWORD GetLastError(void);
]]

function getGraphicsCardHardwareCode()
    local displayDevice = ffi.new("DISPLAY_DEVICEA")
    displayDevice.cb = ffi.sizeof(displayDevice)

    if ffi.C.EnumDisplayDevicesA(nil, 0, displayDevice, 0) ~= 0 then
        local pattern = "PCI\\VEN_(%x+)&DEV_(%x+)"
        local _, _, vendorId, deviceId = ffi.string(displayDevice.DeviceID):find(pattern)
        return vendorId .. ":" .. deviceId
    else
        local err = ffi.C.GetLastError()
        error("Failed to get graphics card hardware code. Error code: " .. err)
    end
end

print(getGraphicsCardHardwareCode())
