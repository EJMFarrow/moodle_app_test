[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

& docker compose exec -T moodle php /var/www/moodle/admin/cli/cfg.php --name=enablewebservices --set=1
& docker compose exec -T moodle php /var/www/moodle/admin/cli/cfg.php --name=enablemobilewebservice --set=1
& docker compose exec -T moodle php /var/www/moodle/admin/cli/cfg.php --component=qtype_stack --name=platform --set=server
& docker compose exec -T moodle php /var/www/moodle/admin/cli/cfg.php --component=qtype_stack --name=maximacommandserver --set=http://goemaxima:8080/maxima
& docker compose exec -T moodle php /var/www/moodle/admin/cli/cfg.php --component=qtype_stack --name=maximaversion --set=default
[string]$seeded = & docker compose exec -T moodle php -r "define('CLI_SCRIPT', true); require '/var/www/moodle/config.php'; echo get_config('core', 'local_stack_demo_seeded') ?: ''; "
$seeded = $seeded.Trim()
if ($LASTEXITCODE -ne 0) { throw 'Unable to check the STACK demo seed state.' }
if ($seeded -ne '1') {
    # The Moodle runtime has a read-only root filesystem. Restore via the
    # writable one-shot installer, which sees the same STACK bind mount.
    & docker compose run --rm moodle-installer /var/www/moodle/admin/cli/restore_backup.php --file=/var/www/moodle/public/question/type/stack/samplequestions/STACK-demo.mbz --categoryid=1
    if ($LASTEXITCODE -ne 0) { throw 'Unable to restore the upstream STACK demo course.' }
    & docker compose exec -T moodle php /var/www/moodle/admin/cli/cfg.php --name=local_stack_demo_seeded --set=1
}
# Stream the small idempotent enrollment helper instead of copying into the
# intentionally read-only Moodle runtime filesystem.
Get-Content -Raw (Join-Path $PSScriptRoot 'seed-demo.php') | & docker compose exec -T moodle php
& docker compose exec -T moodle php /var/www/moodle/admin/cli/purge_caches.php
if ($LASTEXITCODE -ne 0) { throw 'Unable to configure Moodle mobile services and demo data.' }
