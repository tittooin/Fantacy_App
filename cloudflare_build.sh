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

# Prepare build with environment variables
echo "🔧 Configuring Firebase environment variables..."

# Default values (fallback if env vars not set)
FIREBASE_API_KEY=${FIREBASE_API_KEY:-"AIzaSyDVoZoy6_Qz36Xz3P7CbkGSB75Vq0CsJhU"}
FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID:-"axevora11"}
FIREBASE_AUTH_DOMAIN=${FIREBASE_AUTH_DOMAIN:-"axevora11.firebaseapp.com"}
FIREBASE_STORAGE_BUCKET=${FIREBASE_STORAGE_BUCKET:-"axevora11.firebasestorage.app"}
FIREBASE_MESSAGING_SENDER_ID=${FIREBASE_MESSAGING_SENDER_ID:-"526953085440"}
FIREBASE_APP_ID=${FIREBASE_APP_ID:-"1:526953085440:web:e765e8884960196c36b6e5"}
FIREBASE_MEASUREMENT_ID=${FIREBASE_MEASUREMENT_ID:-"G-Z2F4G77KWE"}

# Build web app with dart-define flags
echo "🔨 Building Flutter Web App (Release Mode)..."
flutter build web --release \
  --dart-define=FIREBASE_API_KEY="$FIREBASE_API_KEY" \
  --dart-define=FIREBASE_PROJECT_ID="$FIREBASE_PROJECT_ID" \
  --dart-define=FIREBASE_AUTH_DOMAIN="$FIREBASE_AUTH_DOMAIN" \
  --dart-define=FIREBASE_STORAGE_BUCKET="$FIREBASE_STORAGE_BUCKET" \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID="$FIREBASE_MESSAGING_SENDER_ID" \
  --dart-define=FIREBASE_APP_ID="$FIREBASE_APP_ID" \
  --dart-define=FIREBASE_MEASUREMENT_ID="$FIREBASE_MEASUREMENT_ID"

echo "✅ Build Complete! Output: build/web"
