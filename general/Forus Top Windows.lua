-- create. SYR1337
ffi.cdef([[
    unsigned long GetForegroundWindow();
    bool SetForegroundWindow(long hWnd);
    bool FlashWindow(long hWnd, bool bInvert);
    bool ShowWindow(long hWnd, int nCmdShow);
    bool SetWindowPos(long hWnd, long hWndInsertAfter, int x, int y, int cx, int cy, unsigned int uFlags);
]])
local User32 = ffi.load("User32.dll")
local Kernel32 = ffi.load("Kernel32.dll")
local ClienthWnd = ((ffi.cast("uintptr_t***", ffi.cast("uintptr_t", utils.opcode_scan("engine.dll", "8B 0D ?? ?? ?? ?? 85 C9 74 16 8B 01 8B")) + 2)[0])[0] + 2)[0]
events["round_prestart"]:set(function()
    local hForehWnd = User32.GetForegroundWindow()
    User32.SetWindowPos(ClienthWnd, - 1, 0, 0, 0, 0, 0x0002 + 0x0001)
    User32.SetWindowPos(ClienthWnd, - 2, 0, 0, 0, 0, 0x0002 + 0x0001)
    User32.SetForegroundWindow(ClienthWnd)
    User32.ShowWindow(ClienthWnd, 1)
    User32.FlashWindow(ClienthWnd, true)
end)
