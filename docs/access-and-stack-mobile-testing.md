# Accessing and testing the local STACK mobile environment

## Moodle web site

Use the public HTTPS URL configured in `.env`, not the internal
`http://localhost:8080` health-check endpoint used between containers.

```powershell
Get-Content C:\MoodleApp\.env | Select-String MOODLE_WWWROOT
```

For example, a newly bootstrapped machine might use
`https://192.168.1.10:8443`. The actual address is generated from that
machine's active LAN address, so always use the value in its own `.env` file.

Before accessing it from Windows, trust this setup's private development CA
for the current Windows user:

```powershell
cd C:\MoodleApp
.\scripts\trust-windows-ca.ps1
```

Close and reopen the browser afterwards. This does not install a public
certificate; it trusts only the local Caddy CA generated for this development
environment. If a browser still reports a TLS error after this step, record the
exact error code shown on its error page.

Local accounts:

| Role | Username | Password |
| --- | --- | --- |
| Administrator | `stackadmin` | `StackAdmin!52` |
| Learner | `stackstudent` | `StackStudent!52` |

To test STACK in the browser, sign in as `stackstudent`, open the restored
`STACK-4.4.7-demo` course and its quiz, then attempt a question. Use its
check/submit action and review the resulting feedback. This tests the normal
Moodle, STACK, and GoeMaxima grading path.

## Moodle App / Android emulator

The Moodle App checkout is `C:\MoodleApp\moodleapp` at version 5.2.1.

### 1. Install prerequisites on Windows

Close existing terminals before changing Node, Java, or Android SDK settings.

#### Node.js 22

Moodle App 5.2.1 requires Node `>=22.17 <23`; Node 24 is not supported. A
version manager avoids replacing other projects' Node version. In an elevated
PowerShell window, install Volta:

```powershell
winget install --id Volta.Volta --exact
```

Close and reopen PowerShell, then install the supported Node version:

```powershell
volta install node@22.17.1
node --version
npm --version
```

`node --version` must report `v22.17.x` through `v22.x`. If Volta is not
available in your package sources, install the Windows Node 22 LTS installer
instead and ensure its installation directory comes before any Node 24 path in
`PATH`.

#### JDK

Install a supported LTS JDK (Temurin 21 is a suitable choice):

```powershell
winget install --id EclipseAdoptium.Temurin.21.JDK --exact
```

Open a new PowerShell window and check it:

```powershell
java -version
```

If the command is not found, set `JAVA_HOME` to the installed JDK directory
(for example `C:\Program Files\Eclipse Adoptium\jdk-21...`) and add
`%JAVA_HOME%\bin` to `PATH`, then open a new terminal.

#### Android Studio, SDK, and emulator

Install Android Studio:

```powershell
winget install --id Google.AndroidStudio --exact
```

In Android Studio, complete the first-run setup and use **More Actions** ->
**SDK Manager** to install:

- Android SDK Platform for a current stable API level;
- Android SDK Build-Tools;
- Android SDK Platform-Tools;
- Android SDK Command-line Tools (latest);
- Android Emulator; and
- one Google APIs or Google Play `x86_64` system image for the selected API.

The default SDK location is normally:

```text
%LOCALAPPDATA%\Android\Sdk
```

Set `ANDROID_HOME` to that location, and add these directories to the user
`PATH` if Android Studio did not do so:

```text
%ANDROID_HOME%\platform-tools
%ANDROID_HOME%\emulator
%ANDROID_HOME%\cmdline-tools\latest\bin
```

Open **Device Manager** in Android Studio, create a Pixel-class virtual device,
select the downloaded Google APIs/Google Play system image, and start it. If an
emulator reports that acceleration is unavailable, enable CPU virtualization in
firmware and enable the Windows virtualization features requested by Android
Studio.

Check the command-line tools in a new terminal:

```powershell
adb version
adb devices
sdkmanager --list
```

With the emulator running, `adb devices` must list an `emulator-*` device with
state `device`.

### 2. Build and install

The commands below create a Cordova debug build. They use the checked-out
Moodle App dependencies rather than a globally installed Ionic or Cordova.

1. Confirm the emulator is booted and visible before building:

   ```powershell
   adb devices
   ```

   Continue only when an `emulator-*` entry has state `device`. If more than
   one device is shown, set its serial for the remaining commands:

   ```powershell
   $env:ANDROID_SERIAL = 'emulator-5554'
   ```

2. Build the debug APK from the workspace root:

   ```powershell
   cd C:\MoodleApp
   .\scripts\build-android-debug.ps1
   ```

   The first run executes `npm ci`, builds the Ionic web assets, adds/prepares
   the Cordova Android project, and runs Gradle. If Gradle is not installed,
   the script downloads Gradle 8.14.2 into the ignored `tools` directory for
   this workspace. It can take several minutes while Gradle downloads its
   dependencies. The resulting APK is:

   ```text
   C:\MoodleApp\moodleapp\platforms\android\app\build\outputs\apk\debug\app-debug.apk
   ```

   If the command fails, check `node --version`, `java -version`, `adb devices`,
   and `sdkmanager --list` before retrying. Do not use `npx cap sync`; Moodle
   App 5.2.1 uses Cordova.

3. Export and install the local HTTPS CA. First export the certificate:

   ```powershell
   .\scripts\trust-emulator-ca.ps1
   ```

   Copy it to the emulator:

   ```powershell
   adb push C:\MoodleApp\local\caddy-root.crt /sdcard/Download/caddy-root.crt
   ```

   In the emulator, open **Settings** -> **Security & privacy** -> **More
   security settings** -> **Encryption & credentials** -> **Install a
   certificate** -> **CA certificate**, select `caddy-root.crt`, and confirm.
   Set an emulator screen lock first if Android requires one.

   This checkout's debug network-security configuration trusts user CA
   certificates specifically so the emulator can reach the local Caddy CA. Do
   not carry this configuration into a production APK.

4. Install the APK:

   ```powershell
   adb install -r C:\MoodleApp\moodleapp\platforms\android\app\build\outputs\apk\debug\app-debug.apk
   ```

   `-r` updates the app while preserving its local data. For a clean test run,
   clear its data before starting it:

   ```powershell
   adb shell pm clear com.moodle.moodlemobile
   ```

   Launch it from the emulator launcher, or use:

   ```powershell
   adb shell monkey -p com.moodle.moodlemobile -c android.intent.category.LAUNCHER 1
   ```

5. In the app, select **Add site** and enter the HTTPS `MOODLE_WWWROOT` from
   `C:\MoodleApp\.env` (for example `https://10.126.232.129:8443`). Do not
   enter `localhost`, which would refer to the emulator itself. Sign in
   as `stackstudent`.

6. Open `STACK-4.4.7-demo`, enter its quiz, and attempt a STACK question.
   Verify checking, submission,
   grading, feedback, and review in the app.

7. For a rebuild after app-source changes, rerun
   `C:\MoodleApp\scripts\build-android-debug.ps1`, then repeat the `adb
   install -r` command. If old app assets persist, run `adb shell pm clear
   com.moodle.moodlemobile` before launching again.

### 3. Debug the app and inspect network traffic

The debug APK enables Android WebView remote debugging. With the emulator and
app open, use Chrome on Windows to inspect the WebView:

1. Open `chrome://inspect/#devices`.
2. Enable **Discover USB devices** if it is not already enabled.
3. Under `com.moodle.moodlemobile`, select **inspect**.

Chrome DevTools provides JavaScript errors and logs in **Console**. In
**Network**, enable **Preserve log** and **Disable cache**, reproduce the
action, then inspect the request, response, and timing. A HAR export can
include session cookies and tokens, so do not share it without reviewing or
sanitising it.

To see Android/Cordova logs while reproducing an issue, run:

```powershell
adb logcat -c
adb logcat -v threadtime | Select-String -Pattern 'com.moodle.moodlemobile|chromium|Cordova|System.err|AndroidRuntime'
```

For crash reports only, use:

```powershell
adb logcat -b crash -v time
```

To save the current log buffer for later analysis:

```powershell
adb logcat -d -v threadtime > C:\MoodleApp\local\moodle-app-log.txt
```

Some Moodle App requests use the native advanced-HTTP Cordova plugin and do
not appear in the WebView's DevTools **Network** panel. To inspect all app
traffic, configure an intercepting proxy such as HTTP Toolkit or Charles in
the emulator's extended controls. Use `10.0.2.2` as the proxy host (the
emulator alias for the Windows host) and the proxy's listening port. For HTTPS
inspection, install the proxy CA in the emulator. The debug APK trusts
user-installed CAs; do not use that configuration in a production build.

To correlate an app request with local server output, run:

```powershell
cd C:\MoodleApp
docker compose logs -f moodle caddy
```

## STACK development workbench

Connect directly:

```powershell
ssh stackdev@localhost -p 2223
```

The password is `stackdev`. An interactive login opens in
`/workspace/stack`.

For VS Code, first open `C:\MoodleApp` as a local folder. Then run
**Remote-SSH: Connect to Host**, choose `stack-workbench`, and open
`/workspace/stack`. The checked-in Remote SSH configuration is
`.vscode/ssh-config`.

Install or confirm the Codex extension (`openai.chatgpt`) in the remote
`stack-workbench` authority. Do not rely only on a host-side extension
installation.

The workbench can write `/workspace/stack`. Moodle sees the same checkout as
read-only, so your changes appear to Moodle immediately while its runtime
cannot modify the plugin source.

## Making changes visible

For PHP, template, language, renderer, or CSS changes in STACK:

1. Edit the files in `/workspace/stack`.
2. Purge Moodle caches:

   ```powershell
   cd C:\MoodleApp
   docker compose exec -T moodle php /var/www/moodle/admin/cli/purge_caches.php
   ```

3. Browser testing: hard-refresh the page.
4. Moodle App testing: leave and reopen the activity. If old styling or markup
   remains, sign out and in again, or clear the app's storage and reconnect to
   the site.

Moodle compiles and caches plugin CSS, while the app/WebView may cache rendered
content independently. Purging Moodle caches and refreshing the client is the
reliable cycle after a stylesheet change.

## Useful status and reset commands

```powershell
cd C:\MoodleApp
docker compose ps
Get-Content .\local\setup-record.md
```

`./scripts/reset-demo.ps1 -Confirm` removes only the local Moodle and MariaDB
named data volumes and recreates the demo. It preserves the source checkouts,
the workbench's Codex/VS Code home volume, and the Caddy CA.
