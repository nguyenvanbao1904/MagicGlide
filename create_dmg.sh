#!/bin/bash

# Create DMG installer for MagicGlide
set -e

APP_NAME="MagicGlide"
BUILD_DIR="build"
APP_PATH="$BUILD_DIR/$APP_NAME.app"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"
STAGING_DIR="$BUILD_DIR/dmg_staging"
VOL_NAME="$APP_NAME"

echo "=========================================="
echo "Creating $APP_NAME DMG Installer"
echo "=========================================="

# Check if .app exists, if not build it first
if [ ! -d "$APP_PATH" ]; then
    echo "📦 App bundle not found. Running build.sh first..."
    ./build.sh
fi

echo "🧹 Preparing staging area..."
rm -rf "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$STAGING_DIR"

echo "📂 Copying $APP_NAME.app..."
cp -R "$APP_PATH" "$STAGING_DIR/"

echo "🔗 Creating Applications symlink..."
ln -s /Applications "$STAGING_DIR/Applications"

echo "💿 Packaging DMG with hdiutil..."
hdiutil create \
    -volname "$VOL_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

echo "🧹 Cleaning up temporary files..."
rm -rf "$STAGING_DIR"

echo ""
echo "=========================================="
echo "✅ DMG INSTALLER CREATED SUCCESSFULLY!"
echo "=========================================="
echo "File location: $DMG_PATH"
ls -lh "$DMG_PATH"
echo ""
echo "Users can simply double-click the DMG and drag $APP_NAME.app into Applications!"
