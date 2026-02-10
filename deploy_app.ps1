Write-Host "Starting Deployment Process for Axevora11..." -ForegroundColor Cyan

# 0. Build APK
Write-Host "Building Flutter APK..." -ForegroundColor Yellow
flutter build apk --release

if ($LASTEXITCODE -eq 0) {
    Write-Host "APK Build Successful!" -ForegroundColor Green
    
    # Check APK Size
    $apkPath = "build\app\outputs\flutter-apk\app-release.apk"
    if (Test-Path $apkPath) {
        $apkSize = (Get-Item $apkPath).Length / 1MB
        Write-Host "APK Size: $([math]::Round($apkSize, 2)) MB" -ForegroundColor Cyan
        
        if ($apkSize -gt 25) {
            Write-Host "WARNING: APK is larger than 25MB. Cloudflare Pages might reject this file." -ForegroundColor Red
        }
    }

    # 1. Build Web
    Write-Host "Building Flutter Web App..." -ForegroundColor Yellow
    // Use canvaskit for better performance or html for smaller size? Defaulting to auto/canvaskit
    flutter build web --release 

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Web Build Successful!" -ForegroundColor Green
        
        # 2. Copy APK to Web Folder (Automated Hosting)
        $destPath = "build\web\app-release.apk"
        
        if (Test-Path $apkPath) {
            Copy-Item $apkPath $destPath
            Write-Host "APK Copied to Web Folder for Hosting [$destPath]" -ForegroundColor Cyan
        }
        else {
            Write-Host "Warning: APK not found at $apkPath" -ForegroundColor Red
        }

        # 3. Deploy to Cloudflare
        Write-Host "Uploading to Cloudflare Pages..." -ForegroundColor Yellow
        # Deploy to 'main' branch alias
        npx wrangler pages deploy build/web --project-name fantacy-app --branch main
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Deployment Complete! Your app should be live shortly." -ForegroundColor Green
            Write-Host "Latest APK: https://axevoralabs.com/app-release.apk (Verify URL mapped to domain)" -ForegroundColor Green
        }
        else {
            Write-Host "Deployment Failed." -ForegroundColor Red
        }
    }
    else {
        Write-Host "Web Build Failed. Aborting deployment." -ForegroundColor Red
    }
}
else {
    Write-Host "APK Build Failed. Aborting deployment." -ForegroundColor Red
    Write-Host "Tip: Try running 'flutter clean' if issues persist." -ForegroundColor Gray
}

# Read-Host -Prompt "Press Enter to exit"
