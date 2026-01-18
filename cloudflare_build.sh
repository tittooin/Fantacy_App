#!/bin/bash

# Exit on error
set -e

# 1. Install Flutter if not cached/present
if [ ! -d "flutter" ]; then
    echo "Installing Flutter..."
    git clone https://github.com/flutter/flutter.git -b stable
fi

# 2. Add to Path
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Enable Web
flutter config --enable-web

# 4. Get Dependencies
echo "Getting packages..."
flutter pub get

# 5. Run Build Runner (Generate code for Freezed/Riverpod)
echo "Generating code..."
dart run build_runner build --delete-conflicting-outputs

# 6. Build Web
# Note: RAPID_API_KEY must be set in Cloudflare Environment Variables
echo "Building for Web..."
flutter build web --release --dart-define=RAPID_API_KEY="$RAPID_API_KEY"

echo "Build Complete!"
