local ffi = require("ffi")
ffi.cdef[[

    typedef unsigned long DWORD;
    typedef char CHAR;
    typedef unsigned char BYTE;
    typedef BYTE* LPBYTE;
    typedef const CHAR* LPCSTR;
    typedef int BOOL;
    typedef char* LPSTR;
    typedef DWORD *LPDWORD;

    typedef struct {
        char szVolumeName[256];
        char szFileSystemName[256];
        DWORD dwSerialNumber;
        DWORD dwMaxComponentLength;
        DWORD dwFileSystemFlags;
    } VOLUME_INFORMATION;

    bool GetVolumeInformationA(
        LPSTR lpRootPathName,
        LPSTR lpVolumeNameBuffer,
        DWORD nVolumeNameSize,
        DWORD* lpVolumeSerialNumber,
        DWORD* lpMaximumComponentLength,
        DWORD* lpFileSystemFlags,
        LPSTR lpFileSystemNameBuffer,
        DWORD nFileSystemNameSize
    );
]]

function get_drive_hwid()
    local volume_name_buffer = ffi.new("char[256]")
    local file_system_name_buffer = ffi.new("char[256]")
    local volume_serial_number = ffi.new("unsigned long[1]")
    local maximum_component_length = ffi.new("unsigned long[1]")
    local file_system_flags = ffi.new("unsigned long[1]")
    local lp_root_path_name = "C:\\"
    
    local ret = ffi.C.GetVolumeInformationA(ffi.cast("char *", lp_root_path_name), volume_name_buffer, 256, volume_serial_number, maximum_component_length, file_system_flags, file_system_name_buffer, 256)
    if ret == 0 then return false end
    return string.format("%08X", volume_serial_number[0])
end

print(get_drive_hwid())
