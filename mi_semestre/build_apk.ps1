# Compila el APK de OrganiU en este equipo.
# Uso:  powershell -ExecutionPolicy Bypass -File .\build_apk.ps1

$ErrorActionPreference = 'Stop'

$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:ANDROID_HOME = 'C:\Android\Sdk'
$env:ANDROID_SDK_ROOT = 'C:\Android\Sdk'
$env:PATH = "C:\src\flutter\bin;$env:JAVA_HOME\bin;$env:ANDROID_HOME\platform-tools;$env:PATH"

flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'flutter pub get falló' }

flutter analyze
if ($LASTEXITCODE -ne 0) { throw 'flutter analyze encontró problemas' }

flutter test
if ($LASTEXITCODE -ne 0) { throw 'Las pruebas fallaron' }

flutter build apk --release --split-per-abi
if ($LASTEXITCODE -ne 0) { throw 'La compilación del APK falló' }

flutter build apk --release
if ($LASTEXITCODE -ne 0) { throw 'La compilación del APK universal falló' }

$dist = Join-Path $PSScriptRoot 'dist'
New-Item -ItemType Directory -Force -Path $dist | Out-Null
$out = Join-Path $PSScriptRoot 'build\app\outputs\flutter-apk'
Copy-Item (Join-Path $out 'app-arm64-v8a-release.apk') (Join-Path $dist 'OrganiU-1.0.0-arm64-v8a.apk') -Force
Copy-Item (Join-Path $out 'app-armeabi-v7a-release.apk') (Join-Path $dist 'OrganiU-1.0.0-armeabi-v7a.apk') -Force
Copy-Item (Join-Path $out 'app-release.apk') (Join-Path $dist 'OrganiU-1.0.0-universal.apk') -Force

Write-Host ''
Write-Host 'APK listos en:' (Resolve-Path $dist)
