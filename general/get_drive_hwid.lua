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
    
    BOOL GetVolumeInformationA(LPCSTR lpRootPathName, LPSTR lpVolumeNameBuffer, DWORD nVolumeNameSize, LPDWORD lpVolumeSerialNumber, LPDWORD lpMaximumComponentLength, LPDWORD lpFileSystemFlags, LPSTR lpFileSystemNameBuffer, DWORD nFileSystemNameSize);
    DWORD GetCurrentDirectoryA(DWORD nBufferLength, CHAR* lpBuffer);
    DWORD QueryDosDeviceA(LPCSTR lpDeviceName, CHAR* lpTargetPath, DWORD ucchMax);
]]

function get_hwid()

    local path_buffer = ffi.new("char[260]")
    local path_len = ffi.C.GetCurrentDirectoryA(260, path_buffer)

    local dos_path_buffer = ffi.new("char[260]", "C:")
    local dos_path_len = ffi.C.QueryDosDeviceA(dos_path_buffer, path_buffer, 260)

    local volume_name_buffer = ffi.new("char[256]")
    local volume_serial_number = ffi.new("DWORD[1]")
    local volume_info_result = ffi.C.GetVolumeInformationA(dos_path_buffer, volume_name_buffer, 256, volume_serial_number, nil, nil, nil, 0)

    local hwid = string.format("%04X-%04X", volume_serial_number[0], volume_info_result)
    return hwid
end

print(get_hwid())
