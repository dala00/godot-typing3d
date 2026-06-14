# Web(HTML5)書き出しをCLIで実行。Godot本体は import.ps1 と同じ解決順。
# 使い方: & "...\tools\export_web.ps1"
param(
    [string]$Godot = "",
    [string]$Project = (Resolve-Path (Join-Path $PSScriptRoot "..")),
    [string]$Preset = "Web",
    [string]$Out = ""
)
if (-not $Godot) { $Godot = $env:GODOT_BIN }
if (-not $Godot) {
    $pathFile = Join-Path $PSScriptRoot ".godot-path"
    if (Test-Path $pathFile) { $Godot = (Get-Content $pathFile -Raw).Trim() }
}
if (-not $Godot -or -not (Test-Path $Godot)) {
    Write-Output "NO_GODOT: tools\.godot-path か 環境変数 GODOT_BIN を設定してください。"
    exit 1
}
if (-not $Out) { $Out = Join-Path $Project "exports\typing3d.html" }
New-Item -ItemType Directory -Force (Split-Path $Out) | Out-Null
& $Godot --headless --path $Project --export-release $Preset $Out 2>&1 | Select-Object -Last 30
if (Test-Path $Out) { "EXPORT OK -> $Out" } else { "EXPORT FAILED" }
