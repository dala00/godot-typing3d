# Godot ヘッドレス再インポート。新規アセット(.glb/.png等)をプロジェクトに取り込む。
# 使い方: & "...\tools\import.ps1"
# Godot本体パスの解決順: -Godot 引数 > 環境変数 GODOT_BIN > tools\.godot-path (gitignore済) の中身
param(
    [string]$Godot = "",
    [string]$Project = (Resolve-Path (Join-Path $PSScriptRoot ".."))
)
if (-not $Godot) { $Godot = $env:GODOT_BIN }
if (-not $Godot) {
    $pathFile = Join-Path $PSScriptRoot ".godot-path"
    if (Test-Path $pathFile) { $Godot = (Get-Content $pathFile -Raw).Trim() }
}
if (-not $Godot -or -not (Test-Path $Godot)) {
    Write-Output "NO_GODOT: Godot本体が見つかりません。tools\.godot-path に実行ファイルのパスを書くか、環境変数 GODOT_BIN を設定するか、-Godot で渡してください。"
    exit 1
}
& $Godot --headless --import --path $Project 2>&1 |
    Select-String -Pattern "ERROR|_update_scan_actions|runner|display|\.glb|\.png" |
    Select-Object -First 20
"IMPORT DONE"
