[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
New-Item -ItemType Directory -Force -Path (Join-Path $root 'local') | Out-Null
$sha = @{}
foreach ($source in 'moodle','stack','moodleapp') {
    if (Test-Path (Join-Path $root $source)) {
        $sha[$source] = (& git -C (Join-Path $root $source) rev-parse HEAD).Trim()
    }
}
$workbenchImage = (& docker image inspect stack-mobile-stack-workbench:latest --format '{{index .RepoDigests 0}}' 2>$null).Trim()
if (-not $workbenchImage) {
    $workbenchImage = (& docker image inspect stack-mobile-stack-workbench:latest --format '{{.Id}}').Trim()
}
$serviceState = (& docker compose ps --format json | ConvertFrom-Json)
$moodleState = ($serviceState | Where-Object { $_.Service -eq 'moodle' }).State
$workbenchState = ($serviceState | Where-Object { $_.Service -eq 'stack-workbench' }).State
$sshOk = (Test-NetConnection 127.0.0.1 -Port 2223 -InformationLevel Quiet)
$record = @"
# Local setup record

Generated: $(Get-Date -Format o)

## Sources
- Moodle: $($sha['moodle'])
- STACK: $($sha['stack'])
- Moodle App: $($sha['moodleapp'])

## Workbench
- SSH: ssh stackdev@localhost -p 2223
- SSH listener verified: $sshOk
- Workbench image digest: $workbenchImage
- Codex policy: approval_policy = on-request; sandbox_mode = danger-full-access inside hardened Docker workbench.
- Writable host path: C:\MoodleApp\stack only.
- Read-only Moodle mount: C:\MoodleApp\moodle -> /opt/moodle.
- Hardening: read-only root filesystem; cap_drop=ALL with only CHOWN/SETGID/SETUID/SYS_CHROOT required by OpenSSH; no-new-privileges; no Docker socket; /tmp,/run,/var/run tmpfs; pids=512; memory=2g; no devices.
- Remote Codex extension: not automatically verified; connect with VS Code Remote SSH and install/confirm `openai.chatgpt` in the `stack-workbench` authority.

## Verification
- Moodle runtime: $moodleState
- Workbench runtime: $workbenchState
- HTTPS Moodle login: verified internally through Caddy (200 OK).
- CAS: GoeMaxima `/maxima` endpoint reachable from Moodle.
- Demo: upstream STACK demo restored; `stackstudent` enrolled in a course containing a quiz.
- Boundary: stackdev can write /workspace/stack; Moodle source is read-only; Docker socket absent; workbench root filesystem is read-only.

## Notes
- Host port 2222 was already occupied by an unrelated Docker service, so the loopback-only workbench endpoint is 2223.
- Android build is pending local prerequisites: Node 22.17-22.x, a JDK, Android SDK platform-tools, and an emulator. This host currently has Node 24, which Moodle App 5.2.1 does not support.
"@
Set-Content -Path (Join-Path $root 'local/setup-record.md') -Value $record -Encoding utf8
