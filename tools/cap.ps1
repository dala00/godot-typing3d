param(
    [string]$TitleMatch = "(DEBUG)",
    [string]$Out = "D:\users\documents\godot\typing-3d\tools\shot.png",
    [int]$Wait = 900
)

if ($Wait -gt 0) { Start-Sleep -Milliseconds $Wait }

Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win {
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, uint nFlags);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd);
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
}
"@

# Find the target window by title substring (exclude this console / editors)
$proc = Get-Process | Where-Object {
    $_.MainWindowTitle -and $_.MainWindowTitle -like "*$TitleMatch*"
} | Select-Object -First 1

if (-not $proc) {
    Write-Output "NO_WINDOW: no window matching '$TitleMatch'"
    exit 1
}

$hwnd = $proc.MainWindowHandle
Write-Output "TARGET: '$($proc.MainWindowTitle)' (pid=$($proc.Id))"

$rect = New-Object Win+RECT
[void][Win]::GetWindowRect($hwnd, [ref]$rect)
$w = $rect.Right - $rect.Left
$h = $rect.Bottom - $rect.Top
if ($w -le 0 -or $h -le 0) { Write-Output "BAD_RECT"; exit 1 }

function Save-Bitmap($bmp, $path) { $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png) }

function Test-Black($bmp) {
    # sample a grid; if essentially all-black, treat as failed PrintWindow
    $sx = [Math]::Max(1, [int]($bmp.Width / 12))
    $sy = [Math]::Max(1, [int]($bmp.Height / 12))
    $sum = 0; $n = 0
    for ($x = 0; $x -lt $bmp.Width; $x += $sx) {
        for ($y = 0; $y -lt $bmp.Height; $y += $sy) {
            $c = $bmp.GetPixel($x, $y); $sum += ($c.R + $c.G + $c.B); $n++
        }
    }
    return (($sum / [Math]::Max(1,$n)) -lt 6)
}

# 1) try PrintWindow (works even if hidden)
$bmp = New-Object System.Drawing.Bitmap $w, $h
$g = [System.Drawing.Graphics]::FromImage($bmp)
$hdc = $g.GetHdc()
$ok = [Win]::PrintWindow($hwnd, $hdc, 2) # PW_RENDERFULLCONTENT
$g.ReleaseHdc($hdc); $g.Dispose()

if ($ok -and -not (Test-Black $bmp)) {
    Save-Bitmap $bmp $Out
    Write-Output "OK: PrintWindow -> $Out ($w x $h)"
    $bmp.Dispose()
    exit 0
}
$bmp.Dispose()

# 2) fallback: bring to front (by title) + CopyFromScreen
if ([Win]::IsIconic($hwnd)) { [void][Win]::ShowWindow($hwnd, 9) } # SW_RESTORE
[void][Win]::SetForegroundWindow($hwnd)
Start-Sleep -Milliseconds 350
[void][Win]::GetWindowRect($hwnd, [ref]$rect)
$w = $rect.Right - $rect.Left
$h = $rect.Bottom - $rect.Top
$bmp2 = New-Object System.Drawing.Bitmap $w, $h
$g2 = [System.Drawing.Graphics]::FromImage($bmp2)
$g2.CopyFromScreen($rect.Left, $rect.Top, 0, 0, (New-Object System.Drawing.Size $w, $h))
$g2.Dispose()
Save-Bitmap $bmp2 $Out
Write-Output "OK: CopyFromScreen -> $Out ($w x $h)"
$bmp2.Dispose()
exit 0
