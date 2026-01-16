#!/bin/bash
set -e

echo "Building MenuClock..."
swift build -c release

echo "Creating app bundle..."
rm -rf MenuClock.app
mkdir -p MenuClock.app/Contents/{MacOS,Resources}

# Copy executable
cp .build/release/MenuClock MenuClock.app/Contents/MacOS/

# Copy Info.plist
cp Sources/MenuClock/Resources/Info.plist MenuClock.app/Contents/Info.plist

# Copy pre-built icon files
cp Sources/MenuClock/Resources/icon/built/*.icns Sources/MenuClock/Resources/icon/built/Assets.car MenuClock.app/Contents/Resources/

# Make executable
chmod +x MenuClock.app/Contents/MacOS/MenuClock

echo "✅ MenuClock.app created successfully!"
echo ""
echo "To run: open MenuClock.app"
echo "To install: cp -r MenuClock.app /Applications/"
