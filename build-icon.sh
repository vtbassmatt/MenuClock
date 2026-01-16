#!/bin/bash
set -e

echo "Building MenuClock icon..."

# Build output directory
OUTPUT_DIR="Sources/MenuClock/Resources/icon/built"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Build icon using actool
actool --app-icon AppIcon \
    --compile "$OUTPUT_DIR" \
    --output-partial-info-plist "$OUTPUT_DIR/assetcatalog_generated_info.plist" \
    --minimum-deployment-target 11.0 \
    --platform macosx \
    --target-device mac \
    Sources/MenuClock/Resources/icon/AppIcon.icon

echo "✅ Icon built successfully in $OUTPUT_DIR"
echo "   Files created:"
ls -lh "$OUTPUT_DIR"
