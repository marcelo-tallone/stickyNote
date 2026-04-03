#!/bin/bash
set -e

APP_NAME="StickyNote"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "==> Generando ícono..."
swift create_icon.swift
iconutil -c icns StickyNote.iconset -o StickyNote.icns

echo "==> Compilando $APP_NAME..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

swiftc main.swift \
    -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
    -sdk "$(xcrun --show-sdk-path)" \
    -framework AppKit \
    -framework Foundation

cp Info.plist "$APP_BUNDLE/Contents/Info.plist"
cp StickyNote.icns "$APP_BUNDLE/Contents/Resources/StickyNote.icns"

echo ""
echo "Listo! App creada en: $APP_BUNDLE"
echo ""
echo "Para instalar:"
echo "  cp -r $APP_BUNDLE /Applications/"
