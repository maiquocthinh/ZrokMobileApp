# Build Android APK — Hướng dẫn

## Prerequisites

### 1. Install Fyne CLI
```powershell
go install fyne.io/tools/cmd/fyne@latest
```

### 2. Install JDK 17+
Download: https://adoptium.net/temurin/releases/

Sau khi cài, set:
```powershell
[Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Eclipse Adoptium\jdk-17.x.x-hotspot", "User")
```

### 3. Install Android Command Line Tools
Download: https://developer.android.com/studio#command-line-tools-only

```powershell
# Tạo folder
mkdir C:\Android\Sdk\cmdline-tools\latest

# Giải nén vào C:\Android\Sdk\cmdline-tools\latest

# Set env
[Environment]::SetEnvironmentVariable("ANDROID_HOME", "C:\Android\Sdk", "User")
```

### 4. Install Android SDK components
```powershell
$sdkmanager = "C:\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat"

# Accept licenses
& $sdkmanager --licenses

# Install required components
& $sdkmanager "platforms;android-34" "build-tools;34.0.0" "ndk;26.3.11579264"
```

### 5. Set NDK path
```powershell
[Environment]::SetEnvironmentVariable("ANDROID_NDK_HOME", "C:\Android\Sdk\ndk\26.3.11579264", "User")
```

### 6. Restart terminal
Đóng và mở lại terminal để env vars có hiệu lực.

## Build APK

```powershell
cd d:\Workspace\Backend\Golang\ZrokApp

# Build debug APK (arm64 only — giảm ~75% size)
fyne package --target android/arm64 --app-id com.zrokapp --name "ZrokMobile"
```

Output: `Zrok Mobile.apk` trong project root.

### Install lên device
```powershell
adb install "Zrok Mobile.apk"
```

## Verify env (kiểm tra trước khi build)
```powershell
echo $env:ANDROID_HOME      # → C:\Android\Sdk
echo $env:ANDROID_NDK_HOME  # → C:\Android\Sdk\ndk\26.3.11579264
echo $env:JAVA_HOME         # → C:\Program Files\...jdk-17...
fyne version                # → fyne cli v2.x.x
go version                  # → go1.25.x
```

## Troubleshooting

| Error | Fix |
|-------|-----|
| `fyne: command not found` | `go install fyne.io/tools/cmd/fyne@latest` |
| `ANDROID_HOME not set` | Set env var (step 3) |
| `NDK not found` | Set `ANDROID_NDK_HOME` (step 5) |
| `could not find javac` | Install JDK + set `JAVA_HOME` (step 2) |
| `CGo: exec cc: not found` | NDK path incorrect, verify step 5 |
