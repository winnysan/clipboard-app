#!/bin/bash

# ------------------------------------------------------------------------------
# 🎯 Tento skript buildne a podpíše macOS aplikáciu a vytvorí .dmg súbor pripravený na distribúciu.
# 
# ✅ PRED SPUSTENÍM:
# 1. Uprav hodnoty v premennej VERSION a CERT_ID nižšie.
# 2. Over si, že certifikát existuje pomocou:
#    security find-identity -p codesigning -v
# 3. Uisti sa, že máš nainštalovaný nástroj:
#    brew install create-dmg
# 4. (Voliteľne) odstráň staré verzie aplikácie, ktoré nájdeš pomocou:
#    find ~ /Applications /Library -name "Clipboard.app" 2>/dev/null
#
# 💡 Spustenie:
#    chmod +x build-sign-package.sh
#    ./build-sign-package.sh
# ------------------------------------------------------------------------------

set -e

APP_NAME="Clipboard"
SCHEME="Clipboard"
CONFIGURATION="Release"
VERSION="1.0.0"  # 🔧 Uprav podľa aktuálnej verzie
CERT_ID="Developer ID Application: Marek Vinárčik (9596TA4J3J)"  # 🔧 Uprav podľa mena certifikátu

BUILD_DIR=".build"
ARCHIVE_PATH="${BUILD_DIR}/${APP_NAME}.xcarchive"
APP_EXPORT_PATH="${BUILD_DIR}/export"
DMG_NAME="${APP_NAME}-v${VERSION}.dmg"
DMG_OUTPUT_PATH="dist/${DMG_NAME}"

echo "🧹 Čistenie predchádzajúcich buildov..."
rm -rf "$BUILD_DIR" dist
mkdir -p "$BUILD_DIR" dist

echo "🛠️ Build a archivácia aplikácie..."
xcodebuild clean
xcodebuild archive \
  -project "${APP_NAME}.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGN_IDENTITY="$CERT_ID" \
  OTHER_CODE_SIGN_FLAGS="--deep"

echo "📦 Export podpísanej aplikácie (.app)..."
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath "$APP_EXPORT_PATH"

APP_PATH="${APP_EXPORT_PATH}/${APP_NAME}.app"

echo "💾 Vytváranie .dmg súboru..."
create-dmg \
  --volname "${APP_NAME}" \
  --window-pos 200 120 \
  --window-size 480 300 \
  --icon "${APP_NAME}.app" 120 140 \
  --hide-extension "${APP_NAME}.app" \
  --app-drop-link 360 140 \
  "$DMG_OUTPUT_PATH" \
  "$APP_PATH"

echo "✅ Hotovo!"
echo "📦 Výstupný súbor: $DMG_OUTPUT_PATH"
