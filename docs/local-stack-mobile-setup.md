# Local STACK mobile-test environment

## Fresh clone and prerequisites

This repository is a test harness, not a copy of Moodle, Moodle App, or STACK.
It downloads the pinned upstream source checkouts locally during bootstrap.

Install Git and Docker Desktop for Windows first. Docker Desktop must be
running and configured for Linux containers. For Android testing also install
Node `>=22.17 <23`, a JDK, Android SDK platform-tools (`adb`), Android SDK
Command-line Tools, and an Android emulator. Node 24 is rejected because
Moodle App `v5.2.1` does not support it. Detailed Windows and emulator steps
are in [Accessing and testing](access-and-stack-mobile-testing.md#1-install-prerequisites-on-windows).

Clone this harness into the documented path (the checked-in VS Code SSH setting
uses it), then run bootstrap:

```powershell
git clone https://github.com/YOUR-GITHUB-USER/YOUR-REPOSITORY.git C:\MoodleApp
cd C:\MoodleApp
.\scripts\bootstrap.ps1
```

For Moodle/web setup before installing Android prerequisites, use:

```powershell
.\scripts\bootstrap.ps1 -SkipMobilePrerequisites
```

## Start

Bootstrap creates `.env` from the active Windows network address, clones Moodle
`MOODLE_502_STABLE`, a full Git clone of STACK `master`, Moodle App `v5.2.1`,
and the required Moodle question-behaviour plugins. It builds and starts the
Docker services, installs Moodle, restores the demo course, then records
resolved commit IDs and verification results in `local/setup-record.md`.

The Moodle URL uses the active Windows LAN address on port 8443. Rerun bootstrap
after changing networks. Run `./scripts/trust-emulator-ca.ps1` and install the
exported CA into the emulator before signing in.

Local accounts are `stackadmin` / `StackAdmin!52` and `stackstudent` /
`StackStudent!52`. They are only for this local environment.

## Sandboxed STACK editing

Open `C:\MoodleApp` once as a local VS Code folder; its workspace settings point
Remote SSH at `.vscode/ssh-config`. Then use **Remote-SSH: Connect to Host** and
select `stack-workbench` (password `stackdev`). Port 2222 is occupied by Docker
Desktop on this host, so the local-only workbench uses 2223. Open
`/workspace/stack`, then install/confirm Codex **in the SSH target** if VS Code
does not do so automatically. The supplied `stack-workbench.code-workspace`
opens that exact remote folder and requests the remote `openai.chatgpt` extension.

The workbench is the Docker sandbox: it has a writable STACK checkout and a
read-only Moodle checkout, no Docker socket, dropped Linux capabilities, no new
privileges, a read-only root filesystem, and no host mount beyond STACK source.
It has normal internet access. Codex runs with approvals enabled; its
`danger-full-access` setting remains inside this Docker boundary as described in
[OpenAI's sandbox guidance](https://learn.chatgpt.com/docs/agent-approvals-security#os-level-sandbox).

The mounted `/workspace/stack` directory is the same complete Git repository as
`C:\MoodleApp\stack` on Windows. Its `origin` initially points to the STACK
upstream repository. If you push through a personal fork, configure it from the
workbench once:

```sh
git remote rename origin upstream
git remote add origin https://github.com/YOUR-GITHUB-USER/moodle-qtype_stack.git
git push -u origin HEAD
```

All upstream branches are fetched, including `origin/dev`. The Moodle runtime
shares this checkout, so switching branches changes the code it serves. First
commit or stash any current work, then create and switch to a local tracking
branch with:

```sh
cd /workspace/stack
git switch --track -c dev origin/dev
```

Switch back to the supplied baseline with `git switch master`. Moodle sees the
selected branch immediately because it mounts this directory read-only.

## Reset and verification

`./scripts/reset-demo.ps1 -Confirm` deletes only Moodle and MariaDB named
volumes, then recreates local demo state. It preserves source checkouts, the
Codex home volume, and the Caddy CA.

```powershell
ssh stackdev@localhost -p 2223
# Remote shell:
pwd                              # /workspace/stack
test ! -e /var/run/docker.sock
touch /opt/moodle/.should-fail   # must fail: read-only
```

Run `./scripts/build-android-debug.ps1` after Android prerequisites are ready.
For WebView DevTools, `adb logcat`, proxy, and server-log debugging, see
[Debug the app and inspect network traffic](access-and-stack-mobile-testing.md#3-debug-the-app-and-inspect-network-traffic).
