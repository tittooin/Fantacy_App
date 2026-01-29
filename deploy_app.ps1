Write-Host "Starting Deployment Process for Axevora11..." -ForegroundColor Cyan

# 1. Build The App
Write-Host "Building Flutter Web App..." -ForegroundColor Yellow
flutter build web --release

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build Successful!" -ForegroundColor Green
    
    # 2. Deploy to Cloudflare
    Write-Host "Uploading to Cloudflare Pages..." -ForegroundColor Yellow
<<<<<<< HEAD
    npx wrangler pages deploy build/web --project-name fantasy-cricket-app
=======
    npx wrangler pages deploy build/web --project-name fantasy-cricket-app --branch main
>>>>>>> dev-update
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Deployment Complete! Your app should be live shortly." -ForegroundColor Green
    }
    else {
        Write-Host "Deployment Failed." -ForegroundColor Red
    }
}
else {
    Write-Host "Build Failed. Aborting deployment." -ForegroundColor Red
    Write-Host "Tip: Try running 'flutter clean' if issues persist." -ForegroundColor Gray
}

Read-Host -Prompt "Press Enter to exit"
