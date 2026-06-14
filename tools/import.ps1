# Godot ヘッドレス再インポート。新規アセット(.glb/.png等)をプロジェクトに取り込む。
# 使い方: & "...\tools\import.ps1"
param(
    [string]$Godot = "D:\users\documents\programs\godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe",
    [string]$Project = "D:\users\documents\godot\typing-3d"
)
& $Godot --headless --import --path $Project 2>&1 |
    Select-String -Pattern "ERROR|_update_scan_actions|runner|display|\.glb|\.png" |
    Select-Object -First 20
"IMPORT DONE"
