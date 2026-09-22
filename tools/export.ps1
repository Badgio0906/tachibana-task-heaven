param([string]$GodotExe = "$env:LOCALAPPDATA\Programs\Godot\Godot_v4.5.1-stable_win64_console.exe")
$ErrorActionPreference = 'Stop'
$taskProject = Split-Path -Parent $PSScriptRoot
& $GodotExe --headless --path $taskProject --editor --import --quit
if ($LASTEXITCODE -ne 0) { throw 'Godot import failed' }
& $GodotExe --headless --path $taskProject --export-release Web
if ($LASTEXITCODE -ne 0) { throw 'Godot export failed' }
Copy-Item -LiteralPath (Join-Path $taskProject 'web\audio.js') -Destination (Join-Path $taskProject 'docs\audio.js')
New-Item -ItemType Directory -Path (Join-Path $taskProject 'docs\audio') -Force | Out-Null
Copy-Item -Path (Join-Path $taskProject 'assets\audio\*.wav') -Destination (Join-Path $taskProject 'docs\audio')
Set-Content -LiteralPath (Join-Path $taskProject 'docs\.nojekyll') -Value ''
