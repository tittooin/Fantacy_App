Write-Host "Starting APK Build Process for Axevora11..." -ForegroundColor Cyan

# 1. Pub Get
Write-Host "Getting Dependencies..." -ForegroundColor Yellow
flutter pub get

if ($LASTEXITCODE -eq 0) {
    # 2. Build APK
    Write-Host "Building APK (Release)..." -ForegroundColor Yellow
    flutter build apk --release

    if ($LASTEXITCODE -eq 0) {
        Write-Host "APK Build Successful!" -ForegroundColor Green
        Write-Host "Application Path: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
        
        # Optional: Open Folder
        Invoke-Item "build\app\outputs\flutter-apk\"
    }
    else {
        Write-Host "APK Build Failed." -ForegroundColor Red
        Write-Host "Check the error log above." -ForegroundColor Gray
    }
}
else {
    Write-Host "Dependency Fetch Failed." -ForegroundColor Red
}

Read-Host -Prompt "Press Enter to exit"
