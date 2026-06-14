# 画像を縮小→拡大で柔らかくぼかす(至近距離のディスプレイ風)。
# 使い方: & "...\tools\blur.ps1"   または  ... -Src x.png -Dst y.png -Factor 0.22
param(
    [string]$Src = "D:\users\documents\godot\typing-3d\assets\display.png",
    [string]$Dst = "D:\users\documents\godot\typing-3d\assets\display_soft.png",
    [double]$Factor = 0.22
)
Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile($Src)
$w = $img.Width; $h = $img.Height
$sw = [int]([Math]::Max(2, $w * $Factor)); $sh = [int]([Math]::Max(2, $h * $Factor))
$small = New-Object System.Drawing.Bitmap $sw, $sh
$g1 = [System.Drawing.Graphics]::FromImage($small)
$g1.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g1.DrawImage($img, 0, 0, $sw, $sh)
$g1.Dispose()
$big = New-Object System.Drawing.Bitmap $w, $h
$g2 = [System.Drawing.Graphics]::FromImage($big)
$g2.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g2.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g2.DrawImage($small, 0, 0, $w, $h)
$g2.Dispose()
$big.Save($Dst, [System.Drawing.Imaging.ImageFormat]::Png)
$img.Dispose(); $small.Dispose(); $big.Dispose()
"OK $Dst ($w x $h, from ${sw}x${sh})"
