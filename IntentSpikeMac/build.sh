#!/bin/bash
# Builds IntentSpikeMac.app using only the Command Line Tools — no Xcode.
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$DIR/IntentSpikeMac.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>IntentSpikeMac</string>
  <key>CFBundleDisplayName</key><string>Intent Spike</string>
  <key>CFBundleIdentifier</key><string>com.spike.intentmac</string>
  <key>CFBundleExecutable</key><string>IntentSpikeMac</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>LSApplicationCategoryType</key><string>public.app-category.productivity</string>
</dict>
</plist>
PLIST

# Minimum macOS this app supports — keep in sync with LSMinimumSystemVersion above.
DEPLOY_TARGET="13.0"

SOURCES=(
  "$DIR/Sources/IntentStore.swift"
  "$DIR/Sources/FloatingCard.swift"
  "$DIR/Sources/MenuBarView.swift"
  "$DIR/Sources/ContentView.swift"
  "$DIR/Sources/App.swift"
)

# Build each arch with an explicit target so the binary's minos matches
# DEPLOY_TARGET (not the host SDK), then lipo into a universal binary so it
# runs on both Apple Silicon and Intel.
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT
for ARCH in arm64 x86_64; do
  xcrun --sdk macosx swiftc -parse-as-library -O \
    -target "$ARCH-apple-macos$DEPLOY_TARGET" \
    -o "$BUILD_DIR/IntentSpikeMac-$ARCH" \
    "${SOURCES[@]}"
done
lipo -create -output "$APP/Contents/MacOS/IntentSpikeMac" \
  "$BUILD_DIR/IntentSpikeMac-arm64" "$BUILD_DIR/IntentSpikeMac-x86_64"

# Ad-hoc sign so Gatekeeper lets it run locally.
codesign --force --deep --sign - "$APP" 2>/dev/null || true

echo "Built: $APP"
