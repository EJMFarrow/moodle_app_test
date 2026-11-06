[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
New-Item -ItemType Directory -Force -Path (Join-Path $root 'local') | Out-Null
& docker compose cp caddy:/data/caddy/pki/authorities/local/root.crt local/caddy-root.crt
if ($LASTEXITCODE -ne 0) { throw 'Unable to copy the Caddy local root certificate.' }
Write-Host 'Install local/caddy-root.crt in the Android emulator as a CA certificate, then use the HTTPS Moodle URL from local/setup-record.md.'
