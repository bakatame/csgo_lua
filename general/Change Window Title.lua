local ffi = require("ffi")
ffi.cdef[[
    typedef void* HWND;
    typedef unsigned long DWORD;
    typedef unsigned long HANDLE;
    typedef void *LPARAM;
    typedef struct {
        DWORD dwSize;
        DWORD cntUsage;
        DWORD th32ProcessID;
        DWORD th32DefaultHeapID;
        DWORD th32ModuleID;
        DWORD cntThreads;
        DWORD th32ParentProcessID;
        long pcPriClassBase;
        DWORD dwFlags;
        char szExeFile[260];
    } PROCESSENTRY32;
    typedef PROCESSENTRY32* PPROCESSENTRY32;

    HWND GetForegroundWindow();
    int GetWindowTextA(HWND hWnd, char* lpString, int nMaxCount);
    int SetWindowTextA(HWND hWnd, const char* lpString);
    DWORD GetWindowThreadProcessId(HWND hWnd, DWORD* lpdwProcessId);
    typedef int (__stdcall *WNDENUMPROC)(HWND, LPARAM);
    int EnumWindows(WNDENUMPROC lpEnumFunc, LPARAM lParam);
    HANDLE CreateToolhelp32Snapshot(DWORD dwFlags, DWORD th32ProcessID);
    int Process32First(HANDLE hSnapshot, PPROCESSENTRY32 lppe);
    int Process32Next(HANDLE hSnapshot, PPROCESSENTRY32 lppe);
    void CloseHandle(HANDLE hObject);

]]
local function get_process_id_by_name(process_name)
    local snapshot = ffi.C.CreateToolhelp32Snapshot(0x00000002, 0)
    if snapshot ~= nil then
        local pe32 = ffi.new("PROCESSENTRY32")
        pe32.dwSize = ffi.sizeof("PROCESSENTRY32")
        local success = ffi.C.Process32First(snapshot, pe32)
        while success ~= 0 do
            local name = ffi.string(pe32.szExeFile)
            if name == process_name then
                ffi.C.CloseHandle(snapshot)
                return pe32.th32ProcessID
            end
            success = ffi.C.Process32Next(snapshot, pe32)
        end
        ffi.C.CloseHandle(snapshot)
    end
    return nil
end
local function set_window_text_for_process(process_name, new_title)
    local process_id = get_process_id_by_name(process_name)
    if process_id == nil then
        print("Process not found:", process_name)
        return
    end

    local function enum_windows_callback(hwnd, lparam)
        local window_process_id = ffi.new("DWORD[1]")
        ffi.C.GetWindowThreadProcessId(hwnd, window_process_id)
        if window_process_id[0] == process_id then
            local title = ffi.new("char[?]", 256)
            ffi.C.GetWindowTextA(hwnd, title, 256)
            local window_title = ffi.string(title)
            if window_title ~= "" then
                print("Window title:", window_title)
                ffi.C.SetWindowTextA(hwnd, new_title)
                print("Window title changed.")
            end
        end
        return 1
    end
    local callback_ptr = ffi.cast("WNDENUMPROC", enum_windows_callback)
    if tostring(ffi.typeof(callback_ptr)):find("int *") then
        ffi.C.EnumWindows(callback_ptr, ffi.cast("void *", 0))
    else
        ffi.C.EnumWindows(ffi.cast("int",callback_ptr), 0)
    end
    
end
local function get_window_text_for_process(process_name)
    local temp_window_title
    local process_id = get_process_id_by_name(process_name)
    if process_id == nil then
        print("Process not found:", process_name)
        return
    end
    local function enum_windows_callback(hwnd, lparam)
        local window_process_id = ffi.new("DWORD[1]")
        ffi.C.GetWindowThreadProcessId(hwnd, window_process_id)
        if window_process_id[0] == process_id then
            local title = ffi.new("char[?]", 256)
            ffi.C.GetWindowTextA(hwnd, title, 256)
            local window_title = ffi.string(title)
            if window_title ~= "" then
                temp_window_title = window_title
            end
        end
        return 1
    end
    local callback_ptr = ffi.cast("WNDENUMPROC", enum_windows_callback)
    if tostring(ffi.typeof(callback_ptr)):find("int *") then
        ffi.C.EnumWindows(callback_ptr, ffi.cast("void *", 0))
    else
        ffi.C.EnumWindows(ffi.cast("int",callback_ptr), 0)
    end
    return temp_window_title
end
print(get_window_text_for_process("csgo.exe"))
set_window_text_for_process("csgo.exe", "Counter-Strike: Global Offensive | test window")
