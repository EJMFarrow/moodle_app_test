[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
if ($PSCmdlet.ShouldProcess('Moodle and MariaDB named volumes', 'remove and reseed local demo state')) {
    & docker compose down
    & docker volume rm stack-mobile_mariadb-data stack-mobile_moodle-data 2>$null
    & (Join-Path $PSScriptRoot 'bootstrap.ps1') -SkipMobilePrerequisites
}
