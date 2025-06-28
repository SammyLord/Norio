#!/bin/bash

echo "🚀 Building Norio.app..."

# Clean previous build
rm -rf Norio.app

# Build release version
echo "📦 Building release..."
swift build --configuration release

# Create app bundle structure
echo "🏗️  Creating app bundle..."
mkdir -p Norio.app/Contents/MacOS
mkdir -p Norio.app/Contents/Resources

# Copy executable
cp .build/release/Norio Norio.app/Contents/MacOS/

# Set executable permissions
chmod +x Norio.app/Contents/MacOS/Norio

# Copy resources
cp macOS/macOS.entitlements Norio.app/Contents/Resources/

# Info.plist is already created, no need to recreate

echo "✅ Norio.app built successfully!"
echo "🎯 You can now run: open Norio.app"
echo "📱 Or copy to Applications: cp -r Norio.app /Applications/" 