#!/bin/bash
set -e

echo "Building MenuClock..."
swift build -c release

echo "Building MenuClock icon..."
rm -rf .build/icon
mkdir -p .build/icon
actool --app-icon 3clocks \
    --compile .build/icon/ \
    --output-partial-info-plist .build/icon/assetcatalog_generated_info.plist \
    --minimum-deployment-target 11.0 \
    --platform macosx \
    --target-device mac \
    Sources/MenuClock/Resources/3clocks.icon

echo "Creating app bundle..."
rm -rf MenuClock.app
mkdir -p MenuClock.app/Contents/{MacOS,Resources}

# Copy executable
cp .build/release/MenuClock MenuClock.app/Contents/MacOS/

# Copy Info.plist
cp Sources/MenuClock/Resources/Info.plist MenuClock.app/Contents/Info.plist

# Copy icon files
cp .build/icon/3clocks.icns .build/icon/Assets.car MenuClock.app/Contents/Resources/

# Make executable
chmod +x MenuClock.app/Contents/MacOS/MenuClock

echo "✅ MenuClock.app created successfully!"
echo ""
echo "To run: open MenuClock.app"
echo "To install: cp -r MenuClock.app /Applications/"
