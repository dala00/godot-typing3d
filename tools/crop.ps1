# tools\shot.png の一部を切り出して拡大し tools\crop.png に保存。キャラ等の細部確認用。
# 既定はキーボード中央付近。割合(0..1)で領域指定可。
# 使い方: & "...\tools\crop.ps1"   または  ... -CX 0.3 -CY 0.4 -CW 0.42 -CH 0.52 -Zoom 3
param(
    [string]$In = (Join-Path $PSScriptRoot "shot.png"),
    [string]$Out = (Join-Path $PSScriptRoot "crop.png"),
    [double]$CX = 0.30,
    [double]$CY = 0.40,
    [double]$CW = 0.42,
    [double]$CH = 0.52,
    [int]$Zoom = 3
)
Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile($In)
$x = [int]($img.Width * $CX); $y = [int]($img.Height * $CY)
$w = [int]($img.Width * $CW); $h = [int]($img.Height * $CH)
$crop = New-Object System.Drawing.Bitmap $w, $h
$g = [System.Drawing.Graphics]::FromImage($crop)
$g.DrawImage($img, (New-Object System.Drawing.Rectangle 0, 0, $w, $h), (New-Object System.Drawing.Rectangle $x, $y, $w, $h), [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()
$big = New-Object System.Drawing.Bitmap ($w * $Zoom), ($h * $Zoom)
$g2 = [System.Drawing.Graphics]::FromImage($big)
$g2.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g2.DrawImage($crop, 0, 0, $w * $Zoom, $h * $Zoom)
$g2.Dispose()
$big.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$img.Dispose(); $crop.Dispose(); $big.Dispose()
"OK $Out"
