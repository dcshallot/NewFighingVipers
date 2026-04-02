Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class Model2WindowCommand
{
    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr SendMessageTimeout(
        IntPtr hWnd,
        uint msg,
        UIntPtr wParam,
        IntPtr lParam,
        uint fuFlags,
        uint uTimeout,
        out UIntPtr lpdwResult
    );

    public const uint WM_COMMAND = 0x0111;
    public const uint SMTO_NORMAL = 0x0000;
}
'@

$process = Get-Process |
    Where-Object { $_.ProcessName -in @('EMULATOR', 'emulator_multicpu') -and $_.MainWindowHandle -ne 0 } |
    Select-Object -First 1

if (-not $process) {
    throw 'Model 2 Emulator window not found.'
}

$dumpTextureCacheCommandId = 40025
$commandId = [UIntPtr]::new([uint64]$dumpTextureCacheCommandId)
$result = [UIntPtr]::Zero
$sendResult = [Model2WindowCommand]::SendMessageTimeout(
    $process.MainWindowHandle,
    [Model2WindowCommand]::WM_COMMAND,
    $commandId,
    [IntPtr]::Zero,
    [Model2WindowCommand]::SMTO_NORMAL,
    10000,
    [ref]$result
)

if ($sendResult -eq [IntPtr]::Zero) {
    $errorCode = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
    throw "Failed to send Dump texture cache command. Win32Error=$errorCode"
}

Write-Host "Sent Dump texture cache to PID $($process.Id), HWND $($process.MainWindowHandle)."
