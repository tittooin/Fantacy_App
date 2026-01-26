#!/bin/bash
set -e

echo "🚀 Starting Cloudflare Pages Build for Fantasy Cricket App..."

# Install Flutter if not present
if ! command -v flutter &> /dev/null; then
    echo "📦 Installing Flutter SDK..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
    export PATH="$PATH:`pwd`/flutter/bin"
fi

# Verify Flutter installation
flutter --version

# Get dependencies
echo "📥 Getting Flutter dependencies..."
flutter pub get

# Build web app
echo "🔨 Building Flutter Web App (Release Mode)..."
flutter build web --release

echo "✅ Build Complete! Output: build/web"
