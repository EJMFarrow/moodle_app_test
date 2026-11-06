# Local STACK Moodle App test environment

This Windows/Docker test harness runs Moodle 5.2 with the upstream STACK
question type, GoeMaxima, and a locally built Moodle App 5.2.1 Android debug
APK. It also supplies a hardened SSH workbench for VS Code Remote SSH and the
Codex extension. The harness is versioned here; Moodle, STACK, Moodle App,
Docker data, certificates, credentials, Android outputs, and local setup
records are deliberately recreated locally and are not committed.

## Quick start

1. Install Docker Desktop, Git, Node 22.17–22.x, a JDK, Android Studio with an
   emulator, Android SDK Platform-Tools, and Android SDK Command-line Tools.
   The detailed prerequisite and emulator instructions are in
   [docs/access-and-stack-mobile-testing.md](docs/access-and-stack-mobile-testing.md#1-install-prerequisites-on-windows).
2. Clone this repository into `C:\MoodleApp`, open PowerShell there, and run:

   ```powershell
   .\scripts\bootstrap.ps1
   ```

   This clones Moodle `MOODLE_502_STABLE`, STACK `master`, and Moodle App
   `v5.2.1`, starts the stack, and seeds a demo course. Use
   `-SkipMobilePrerequisites` to prepare just the server first.
3. Follow the [Moodle App build, certificate, install, and test steps](docs/access-and-stack-mobile-testing.md#2-build-and-install).

The public Moodle URL is the `MOODLE_WWWROOT` value in the locally generated
`.env`; it is usually `https://<your-Windows-LAN-IP>:8443`. Do not use
`http://localhost:8080` in the Android app.

## Documentation

- [Full access, build, emulator, test, debugging, and cache-refresh guide](docs/access-and-stack-mobile-testing.md)
- [Bootstrap, sandboxed VS Code/Codex workbench, and STACK Git workflow](docs/local-stack-mobile-setup.md)
- [Publishing this harness to an empty GitHub repository](docs/publishing-to-github.md)

Local credentials are development-only and are documented in the access guide.
Do not expose this environment or its generated `.env`, `local`, or source
checkout directories on a public server.
