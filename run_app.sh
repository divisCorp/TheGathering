#!/bin/zsh
# Script to run The Gathering app
# Make executable: chmod +x run_app.sh
# Run: ./run_app.sh

export PATH="$HOME/development/flutter/bin:$PATH"

echo "=== The Gathering Setup ==="
flutter --version

echo "=== Pub get ==="
flutter pub get

echo "=== Check for issues ==="
flutter analyze || echo "Analyze may have warnings, check code."

echo "=== To run on device/emulator: flutter run ==="
echo "Make sure you have a device: flutter devices"
echo "Replace SUPABASE keys in .env with real ones from your Supabase project."
echo "Run migrations in supabase/migrations/"

echo "Ready!"
