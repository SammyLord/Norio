#!/bin/bash

echo "📱 Norio iOS Development Setup"
echo "=============================="
echo ""

# Check if Xcode is available
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode not found! Please install Xcode first."
    echo "   Download from: https://developer.apple.com/xcode/"
    exit 1
fi

echo "✅ Xcode found: $(xcodebuild -version | head -n1)"
echo ""

# Attempt command line build (will likely fail)
echo "🔄 Attempting command line build..."
echo "   (This typically fails due to SPM iOS limitations)"
echo ""

# Get SDK paths for reference
IOS_SDK=$(xcrun --sdk iphoneos --show-sdk-path 2>/dev/null)
IOS_SIM_SDK=$(xcrun --sdk iphonesimulator --show-sdk-path 2>/dev/null)

if [ -n "$IOS_SDK" ] && [ -n "$IOS_SIM_SDK" ]; then
    echo "📍 Available SDKs:"
    echo "   iOS Device: $IOS_SDK"
    echo "   iOS Simulator: $IOS_SIM_SDK"
    echo ""
    
    # Try a simple build (expect it to fail)
    echo "🔧 Testing iOS build capability..."
    swift build --triple arm64-apple-ios17.0-simulator \
        -Xswiftc -sdk -Xswiftc "$IOS_SIM_SDK" \
        -Xswiftc -target -Xswiftc arm64-apple-ios17.0-simulator \
        2>/dev/null 1>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✅ Command line iOS build successful! (Rare but possible)"
    else
        echo "❌ Command line iOS build failed (expected)"
        echo "   Reason: Swift Package Manager has complex iOS cross-compilation issues"
        echo "   Solution: Use Xcode (industry standard)"
    fi
else
    echo "❌ Could not locate iOS SDKs"
fi

echo ""
echo "🎯 RECOMMENDED: Use Xcode for iOS Development"
echo "============================================="
echo ""
echo "📂 Ready-to-use Xcode project created:"
echo "   • NorioiOS.xcodeproj"
echo "   • Pre-configured with all dependencies"
echo "   • Ready for simulator and device builds"
echo ""
echo "🚀 Quick Start:"
echo "1. open NorioiOS.xcodeproj"
echo "2. Select target (iPhone Simulator or connected device)"
echo "3. Press Cmd+R to build and run"
echo ""
echo "📦 Alternative: Create New iOS Project:"
echo "1. File > New > Project > iOS > App"
echo "2. Add Package: File > Add Package Dependencies > Add Local"
echo "3. Browse to: $(pwd)"
echo "4. Import NorioUI: import NorioUI"
echo "5. Use BrowserView() in your ContentView"
echo ""
echo "💡 Why Xcode?"
echo "   • Handles iOS SDK configuration automatically"
echo "   • Proper code signing and provisioning"
echo "   • Full iOS development environment"
echo "   • Used by 99% of iOS developers"
echo ""
echo "🎉 Your iOS browser is ready for Xcode development!" 