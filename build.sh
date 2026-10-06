#!/bin/bash
# Builds unADHD.app using only the Command Line Tools — no Xcode.
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$DIR/unADHD.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>unADHD</string>
  <key>CFBundleDisplayName</key><string>unADHD</string>
  <key>CFBundleIdentifier</key><string>com.unadhd.app</string>
  <key>CFBundleExecutable</key><string>unADHD</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.6</string>
  <key>CFBundleVersion</key><string>4</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>LSApplicationCategoryType</key><string>public.app-category.productivity</string>
  <key>NSMicrophoneUsageDescription</key><string>unADHD listens only while you hold the mic button, to turn your spoken intent into text. Audio is processed on your Mac.</string>
  <key>NSSpeechRecognitionUsageDescription</key><string>Speech recognition runs on-device to transcribe the intent you dictate — nothing is sent to Apple.</string>
</dict>
</plist>
PLIST

# Bundle the mascot + menu-bar glyph + app icon.
cp "$DIR/Resources/mascot.png"   "$APP/Contents/Resources/mascot.png"
cp "$DIR/Resources/mascot_hi.png" "$APP/Contents/Resources/mascot_hi.png"
cp "$DIR/Resources/menubar.png"  "$APP/Contents/Resources/menubar.png"
cp "$DIR/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

xcrun --sdk macosx swiftc -parse-as-library -O \
  -o "$APP/Contents/MacOS/unADHD" \
  "$DIR/Sources/Theme.swift" \
  "$DIR/Sources/Onboarding.swift" \
  "$DIR/Sources/Speech.swift" \
  "$DIR/Sources/LoginItem.swift" \
  "$DIR/Sources/HotKeyManager.swift" \
  "$DIR/Sources/QuickCapture.swift" \
  "$DIR/Sources/NudgeEngine.swift" \
  "$DIR/Sources/FrontmostTracker.swift" \
  "$DIR/Sources/IntentStore.swift" \
  "$DIR/Sources/FloatingCard.swift" \
  "$DIR/Sources/MenuBarView.swift" \
  "$DIR/Sources/ContentView.swift" \
  "$DIR/Sources/App.swift"

codesign --force --deep --sign - "$APP" 2>/dev/null || true
echo "Built: $APP"
