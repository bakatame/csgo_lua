--[[
  I don't know if this works, because wProcessorArchitecture returns 0 anyway
  If you find it different from mine, then it might be useful
  Example hwid: 0000024A-7100-0017-0000-000C00000FFF
]]

local ffi = require("ffi")
ffi.cdef[[

    typedef uint32_t DWORD;
    typedef uint16_t WORD;
    typedef void* LPVOID;
    typedef uint32_t DWORD_PTR;
    
    typedef struct {
        union {
            DWORD dwOemId;
            struct {
                WORD wProcessorArchitecture;
                WORD wReserved;
            };
        } ;
        DWORD dwPageSize;
        LPVOID lpMinimumApplicationAddress;
        LPVOID lpMaximumApplicationAddress;
        DWORD_PTR dwActiveProcessorMask;
        DWORD_PTR dwNumberOfProcessors;
        DWORD dwProcessorType;
        DWORD dwAllocationGranularity;
        WORD wProcessorLevel;
        WORD wProcessorRevision;
    } SYSTEM_INFO;

    void GetSystemInfo(SYSTEM_INFO *lpSystemInfo);
]]

function get_hwid()
    local sys_info = ffi.new("SYSTEM_INFO")
    ffi.C.GetSystemInfo(sys_info)
    local hwid = string.format("%08X-%04X-%04X-%04X-%04X%08X", 
                               sys_info.dwProcessorType,
                               sys_info.wProcessorRevision,
                               sys_info.wProcessorLevel,
                               sys_info.wProcessorArchitecture,
                               sys_info.dwNumberOfProcessors,
                               sys_info.dwActiveProcessorMask)
    return hwid
end

print(get_hwid())
