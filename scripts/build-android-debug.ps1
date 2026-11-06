[CmdletBinding()]
param(
    [switch]$RefreshDependencies
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Push-Location (Join-Path $root 'moodleapp')
try {
    $androidHome = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
    if (-not (Test-Path (Join-Path $androidHome 'cmdline-tools'))) {
        throw "Android SDK Command-line Tools are missing from $androidHome. In Android Studio: More Actions -> SDK Manager -> SDK Tools -> select Android SDK Command-line Tools (latest)."
    }
    $workspaceGradle = Join-Path $root 'tools\gradle-8.14.2\bin'
    if (-not (Get-Command gradle -ErrorAction SilentlyContinue) -and -not (Test-Path (Join-Path $workspaceGradle 'gradle.bat'))) {
        # Keep this tool outside Git. It supplies Cordova with Gradle when a
        # fresh Windows/Android Studio install has no system Gradle available.
        $gradleVersion = '8.14.2'
        $toolsDirectory = Join-Path $root 'tools'
        $archive = Join-Path $toolsDirectory "gradle-$gradleVersion-bin.zip"
        New-Item -ItemType Directory -Force -Path $toolsDirectory | Out-Null
        Write-Host "Downloading Gradle $gradleVersion for this workspace..."
        Invoke-WebRequest -Uri "https://services.gradle.org/distributions/gradle-$gradleVersion-bin.zip" -OutFile $archive
        Expand-Archive -LiteralPath $archive -DestinationPath $toolsDirectory -Force
    }
    if (-not (Get-Command gradle -ErrorAction SilentlyContinue) -and (Test-Path (Join-Path $workspaceGradle 'gradle.bat'))) {
        $env:PATH = "$workspaceGradle;$env:PATH"
    }
    if (-not (Get-Command gradle -ErrorAction SilentlyContinue)) {
        throw 'Gradle is not on PATH. Install Gradle, reopen PowerShell, then rerun this script.'
    }
    $dependencies = Join-Path (Get-Location) 'node_modules'
    if ($RefreshDependencies -or -not (Test-Path $dependencies)) {
        npm ci
        if ($LASTEXITCODE -ne 0) { throw 'npm ci failed.' }
    }
    # Cordova packages this local plugin while adding Android. Build its
    # generated www/index.js first so the package has the declared js-module.
    $previousCordovaPlugins = $env:CORDOVA_PLUGINS
    $env:CORDOVA_PLUGINS = 'cordova-plugin-moodleapp'
    & node (Join-Path (Get-Location) 'scripts/cordova-hooks/before_plugin_add.js')
    if ($LASTEXITCODE -ne 0) { throw 'Unable to build cordova-plugin-moodleapp.' }
    $env:CORDOVA_PLUGINS = $previousCordovaPlugins
    $androidPlatform = Join-Path (Get-Location) 'platforms/android'
    if (-not (Test-Path $androidPlatform)) {
        npx ionic cordova platform add android
        if ($LASTEXITCODE -ne 0) { throw 'Unable to add the Cordova Android platform.' }
    }
    # Cordova Android owns the Gradle invocation. Do not call gradlew.bat
    # directly: Cordova 14's generated project creates it during preparation.
    npx ionic cordova build android --debug
    if ($LASTEXITCODE -ne 0) { throw 'Cordova/Gradle debug APK build failed. Re-run "npx ionic cordova build android --debug --verbose" from moodleapp for details.' }
} finally {
    Pop-Location
}
