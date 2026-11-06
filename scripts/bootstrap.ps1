[CmdletBinding()]
param(
    [switch]$SkipMobilePrerequisites,
    [switch]$SkipAndroidExtensionInstall
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Require-Command([string]$Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "$Name is required. Install it, then run this script again."
    }
}

Require-Command git
Require-Command docker
if (-not $SkipMobilePrerequisites) {
    $node = Get-Command node -ErrorAction SilentlyContinue
    $java = Get-Command java -ErrorAction SilentlyContinue
    $adb = Get-Command adb -ErrorAction SilentlyContinue
    if (-not $node -or -not $java -or -not $adb) {
        throw 'Mobile prerequisites missing. Install Node 22.x, a JDK, and Android SDK platform-tools; or use -SkipMobilePrerequisites for server setup.'
    }
    $nodeVersion = (& node --version).Trim().TrimStart('v')
    if ([version]$nodeVersion -lt [version]'22.17.0' -or [version]$nodeVersion -ge [version]'23.0.0') {
        throw "Moodle App v5.2.1 requires Node >=22.17 and <23; found $nodeVersion."
    }
}

function Clone-IfMissing([string]$Path, [string[]]$CloneArguments) {
    if (-not (Test-Path $Path)) {
        & git clone @CloneArguments $Path
        if ($LASTEXITCODE -ne 0) { throw "Git clone failed for $Path." }
    }
}

Clone-IfMissing (Join-Path $root 'moodle') @('--branch', 'MOODLE_502_STABLE', '--depth', '1', 'https://github.com/moodle/moodle.git')
# Keep STACK as a complete Git clone: developers work in this checkout through
# the workbench and may need its branches, tags, and history when preparing a
# change to push to GitHub.
Clone-IfMissing (Join-Path $root 'stack') @('--branch', 'master', 'https://github.com/maths/moodle-qtype_stack.git')
Clone-IfMissing (Join-Path $root 'moodleapp') @('--branch', 'v5.2.1', '--depth', '1', 'https://github.com/moodlehq/moodleapp.git')
Clone-IfMissing (Join-Path $root 'moodle/public/question/behaviour/dfexplicitvaildate') @('--depth', '1', 'https://github.com/maths/moodle-qbehaviour_dfexplicitvaildate.git')
Clone-IfMissing (Join-Path $root 'moodle/public/question/behaviour/dfcbmexplicitvaildate') @('--depth', '1', 'https://github.com/maths/moodle-qbehaviour_dfcbmexplicitvaildate.git')
Clone-IfMissing (Join-Path $root 'moodle/public/question/behaviour/adaptivemultipart') @('--depth', '1', 'https://github.com/maths/moodle-qbehaviour_adaptivemultipart.git')
Clone-IfMissing (Join-Path $root 'moodle/public/question/bank/importasversion') @('--depth', '1', 'https://github.com/maths/moodle-qbank_importasversion.git')

$ipConfig = Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -and $_.IPv4Address } | Select-Object -First 1
if (-not $ipConfig) { throw 'Unable to find an active IPv4 interface with a default gateway.' }
$hostIp = $ipConfig.IPv4Address.IPAddress
$wwwRoot = "https://${hostIp}:8443"

$envLines = @(
    'COMPOSE_PROJECT_NAME=stack-mobile',
    "MOODLE_HOST=$hostIp",
    "MOODLE_WWWROOT=$wwwRoot",
    'WORKBENCH_SSH_PORT=2223',
    'MYSQL_DATABASE=moodle',
    'MYSQL_USER=moodle',
    'MYSQL_PASSWORD=moodle',
    'MYSQL_ROOT_PASSWORD=moodle-root',
    'MOODLE_ADMIN_PASSWORD=StackAdmin!52',
    'MOODLE_STUDENT_PASSWORD=StackStudent!52'
)
Set-Content -Path (Join-Path $root '.env') -Value $envLines -Encoding ascii

& docker compose build moodle stack-workbench
if ($LASTEXITCODE -ne 0) { throw 'Container build failed.' }
& docker compose up -d db goemaxima
if ($LASTEXITCODE -ne 0) { throw 'Database/CAS startup failed.' }

function Get-MoodleTableCount {
    $count = & docker compose exec -T db mariadb -umoodle -pmoodle -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='moodle';"
    if ($LASTEXITCODE -ne 0) { throw 'Unable to query the Moodle database.' }
    return [int]($count | Select-Object -Last 1)
}

$configPath = Join-Path $root 'moodle/config.php'
if (-not (Test-Path $configPath)) {
    & docker compose run --rm moodle-installer /var/www/moodle/admin/cli/install.php --non-interactive --agree-license --lang=en --wwwroot=$wwwRoot --dataroot=/var/moodledata --dbtype=mariadb --dbhost=db --dbname=moodle --dbuser=moodle --dbpass=moodle --fullname='STACK Mobile Development' --shortname=STACKDEV --adminuser=stackadmin --adminpass='StackAdmin!52' --adminemail=stackadmin@example.invalid
    if ($LASTEXITCODE -ne 0) { throw 'Moodle installation failed.' }
    & docker compose run --rm --entrypoint sh moodle-installer -lc 'chmod 644 /var/www/moodle/config.php'
}
elseif ((Get-MoodleTableCount) -eq 0) {
    # install.php writes config.php before its database phase. Recover a
    # previous interrupted first install using Moodle's supported CLI command.
    & docker compose run --rm moodle-installer /var/www/moodle/admin/cli/install_database.php --agree-license --adminuser=stackadmin --adminpass='StackAdmin!52' --adminemail=stackadmin@example.invalid --fullname='STACK Mobile Development' --shortname=STACKDEV
    if ($LASTEXITCODE -ne 0) { throw 'Moodle database installation failed.' }
    & docker compose run --rm --entrypoint sh moodle-installer -lc 'chmod 644 /var/www/moodle/config.php'
}

# Caddy terminates local HTTPS and proxies to Apache over the internal Docker
# network. Tell Moodle to trust that boundary so it does not redirect in a loop.
& docker compose run --rm --entrypoint sh moodle-installer -lc "grep -q '\`\$CFG->reverseproxy' /var/www/moodle/config.php || sed -i '/^require_once/i\`\$CFG->reverseproxy = true;\n\`\$CFG->sslproxy = true;\n' /var/www/moodle/config.php"
if ($LASTEXITCODE -ne 0) { throw 'Unable to configure Moodle reverse-proxy settings.' }

& docker compose up -d moodle caddy stack-workbench
if ($LASTEXITCODE -ne 0) { throw 'Runtime startup failed.' }
& (Join-Path $PSScriptRoot 'seed-demo.ps1')
& (Join-Path $PSScriptRoot 'record-setup.ps1')
if (-not $SkipAndroidExtensionInstall) {
    Write-Host 'In VS Code Remote SSH, install Codex in the stack-workbench target if it is not installed automatically.'
}
Write-Host "Ready: $wwwRoot  |  ssh stackdev@localhost -p 2223"
