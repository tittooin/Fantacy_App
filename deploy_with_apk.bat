@echo off
echo ==========================================
echo   AXEVORA11: BUILD & DEPLOY PIPELINE
echo ==========================================

echo [1/4] Building Android APK (Release)...
call flutter build apk --release
if %errorlevel% neq 0 exit /b %errorlevel%

echo [2/4] Copying APK to Web Assets...
copy "build\app\outputs\flutter-apk\app-release.apk" "web\app-release.apk"
if %errorlevel% neq 0 echo Warning: Failed to copy APK to web source.

echo [3/4] Building Web App (Release)...
call flutter build web --release --no-tree-shake-icons
if %errorlevel% neq 0 exit /b %errorlevel%

echo [4/4] Deploying to Cloudflare...
echo NOTE: Ensure you are logged in to Wrangler.
call npx wrangler pages deploy build/web --project-name fantacy-app
if %errorlevel% neq 0 exit /b %errorlevel%

echo ==========================================
echo   DEPLOYMENT SUCCESSFUL!
echo   Website: https://axevora11.in
echo   APK Link: https://axevora11.in/app-release.apk
echo ==========================================
