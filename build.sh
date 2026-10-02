#!/bin/bash

# Build script for MagicGlide app (Universal Binary)
set -e

APP_NAME="MagicGlide"
BUNDLE_ID="com.magicglide.app"
BUILD_DIR="build"
APP_PATH="$BUILD_DIR/$APP_NAME.app"

echo "=========================================="
echo "Building MagicGlide (Universal Binary)"
echo "=========================================="

# Clean previous build
rm -rf "$APP_PATH"
mkdir -p "$BUILD_DIR"

# Create app bundle structure
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"
MODULE_CACHE_DIR="$BUILD_DIR/.module-cache"
BUILD_TMP_DIR="$BUILD_DIR/.tmp"
mkdir -p "$MODULE_CACHE_DIR" "$BUILD_TMP_DIR"
export TMPDIR="$PWD/$BUILD_TMP_DIR"

SWIFT_SOURCES=(
    Sources/Actions/GestureSlot.swift
    Sources/Actions/GestureAction.swift
    Sources/Actions/GestureAction+Compatibility.swift
    Sources/Actions/GestureAction+Presentation.swift
    Sources/Actions/ActionContext.swift
    Sources/Actions/GestureEvent.swift
    Sources/Actions/GestureDispatcher.swift
    Sources/Actions/ActionExecutor.swift
    Sources/Actions/GestureConfiguration.swift
    Sources/Settings/Preferences.swift
    Sources/Settings/PreferenceStore.swift
    Sources/Core/SurfaceTouch.swift
    Sources/Gestures/TapDetector.swift
    Sources/Gestures/TwoFingerTapDetector.swift
    Sources/Gestures/ThreeFingerGestureDetector.swift
    Sources/Gestures/PinchZoomDetector.swift
    Sources/Gestures/TwoFingerMoveZoomDetector.swift
    Sources/Gestures/TwoFingerSwipeDetector.swift
    Sources/System/HUDOverlay.swift
    Sources/System/SystemControl.swift
    Sources/Core/TrackpadModeHUD.swift
    Sources/Core/TrackpadModeController.swift
    Sources/Core/MultitouchSource.swift
    Sources/Core/GestureEngine.swift
    Sources/UI/MouseDeviceInfo.swift
    Sources/UI/Localization.swift
    Sources/UI/MagicMouseCanvasView.swift
    Sources/UI/SettingsViewModel.swift
    Sources/UI/SettingsPreferencesView.swift
    Sources/UI/SettingsWindowController.swift
    Sources/App/ClickSynthesizer.swift
    Sources/App/EventTapController.swift
    Sources/App/MenuBuilder.swift
    Sources/App/AppDelegate.swift
    Sources/App/main.swift
)

FRAMEWORK_FLAGS=(
    -import-objc-header Sources/Core/MultitouchBridge.h
    -framework Cocoa
    -framework SwiftUI
    -framework IOBluetooth
    -framework IOKit
    -framework ApplicationServices
    -framework CoreAudio
    -framework AudioToolbox
    -F /System/Library/PrivateFrameworks
    -framework MultitouchSupport
    -framework DisplayServices
    -Xlinker -rpath -Xlinker /System/Library/PrivateFrameworks
)

# Compile for Apple Silicon (arm64)
echo "📦 Compiling for Apple Silicon (arm64)..."
swiftc -o "$BUILD_DIR/${APP_NAME}_arm64" \
    -target arm64-apple-macos11.0 \
    -module-cache-path "$MODULE_CACHE_DIR" \
    "${FRAMEWORK_FLAGS[@]}" \
    "${SWIFT_SOURCES[@]}"

# Compile for Intel (x86_64)
echo "📦 Compiling for Intel (x86_64)..."
swiftc -o "$BUILD_DIR/${APP_NAME}_x86_64" \
    -target x86_64-apple-macos11.0 \
    -module-cache-path "$MODULE_CACHE_DIR" \
    "${FRAMEWORK_FLAGS[@]}" \
    "${SWIFT_SOURCES[@]}"

# Create universal binary
echo "🔗 Creating universal binary..."
lipo -create \
    "$BUILD_DIR/${APP_NAME}_arm64" \
    "$BUILD_DIR/${APP_NAME}_x86_64" \
    -output "$APP_PATH/Contents/MacOS/$APP_NAME"

# Clean up temporary object files
rm -f "$BUILD_DIR/${APP_NAME}_arm64" "$BUILD_DIR/${APP_NAME}_x86_64"
rm -rf "$MODULE_CACHE_DIR" "$BUILD_TMP_DIR"

# Copy Info.plist
if [ -f "Resources/Info.plist" ]; then
    cp Resources/Info.plist "$APP_PATH/Contents/Info.plist"
elif [ -f "Info.plist" ]; then
    cp Info.plist "$APP_PATH/Contents/Info.plist"
fi

# Ad-hoc sign the app bundle so macOS Accessibility permissions persist
echo "🔏 Codesigning app bundle..."
codesign --force --deep --sign - "$APP_PATH"

echo ""
echo "=========================================="
echo "✅ UNIVERSAL BINARY BUILD COMPLETE!"
echo "=========================================="
echo ""
echo "App location: $APP_PATH"
echo "Architectures: arm64 (Apple Silicon) + x86_64 (Intel)"
echo ""
echo "To run the app:"
echo "  open $APP_PATH"
echo ""
echo "To install the app (copy to Applications):"
echo "  cp -r $APP_PATH /Applications/"
echo ""
