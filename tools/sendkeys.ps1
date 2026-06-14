# 実行中ゲーム窓(既定 (DEBUG))を前面化してキー入力する。操作の検証用。
#  文字列タイプ:   & sendkeys.ps1 -Keys "godot"
#  キー長押し:     & sendkeys.ps1 -Key W -Hold 700    (W/A/S/D/SPACE/UP/DOWN/LEFT/RIGHT)
param(
    [string]$Keys = "",
    [string]$Key = "",
    [int]$Hold = 0,
    [string]$TitleMatch = "(DEBUG)",
    [int]$Delay = 300
)
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WinIn {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int n);
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
}
"@
$proc = Get-Process | Where-Object { $_.MainWindowTitle -and $_.MainWindowTitle -like "*$TitleMatch*" } | Select-Object -First 1
if (-not $proc) { Write-Output "NO_WINDOW"; exit 1 }
$h = $proc.MainWindowHandle
if ([WinIn]::IsIconic($h)) { [void][WinIn]::ShowWindow($h, 9) }
[void][WinIn]::SetForegroundWindow($h)
Start-Sleep -Milliseconds 300

if ($Key -ne "") {
    $vk = @{ "W"=0x57; "A"=0x41; "S"=0x53; "D"=0x44; "SPACE"=0x20;
             "UP"=0x26; "DOWN"=0x28; "LEFT"=0x25; "RIGHT"=0x27 }[$Key.ToUpper()]
    if (-not $vk) { Write-Output "BAD_KEY $Key"; exit 1 }
    [WinIn]::keybd_event([byte]$vk, 0, 0, [UIntPtr]::Zero)        # down
    Start-Sleep -Milliseconds $Hold
    [WinIn]::keybd_event([byte]$vk, 0, 2, [UIntPtr]::Zero)        # up (KEYEVENTF_KEYUP)
    "HELD $Key for ${Hold}ms"
    exit 0
}

$ws = New-Object -ComObject WScript.Shell
foreach ($c in $Keys.ToCharArray()) {
    $ws.SendKeys($c)
    Start-Sleep -Milliseconds $Delay
}
"SENT '$Keys'"
