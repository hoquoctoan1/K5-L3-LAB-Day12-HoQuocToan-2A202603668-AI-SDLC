$ErrorActionPreference = 'Stop'
$toolsRoot = Join-Path (Split-Path $PSScriptRoot -Parent) '..\.tools'
$nodeFolder = Get-ChildItem -LiteralPath $toolsRoot -Directory -Filter 'node-v24.*-win-x64' | Sort-Object Name -Descending | Select-Object -First 1
if (-not $nodeFolder) { throw 'Missing workspace Node.js. Install Node.js 24 LTS or ask to restore lab/.tools.' }
$env:PATH = "$($nodeFolder.FullName);$env:PATH"
Write-Host "Node.js activated for this terminal: $(node --version). Use npm.cmd on Windows."
