#!/bin/bash

echo "📱 Creating Norio iOS App"
echo "========================"
echo ""

# Create iOS app directory structure
mkdir -p NorioiOS
cd NorioiOS

# Create App.swift
cat > App.swift << 'EOF'
import SwiftUI

@main
struct NorioApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
EOF

# Create ContentView.swift (without NorioUI import initially)
cat > ContentView.swift << 'EOF'
import SwiftUI
// TODO: Add 'import NorioUI' after adding package dependency in Xcode

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Norio Browser")
                .font(.title)
            Text("Ready for package setup!")
                .font(.caption)
        }
        .padding()
        
        // TODO: Replace with BrowserView() after adding NorioUI package
        // BrowserView()
    }
}

#Preview {
    ContentView()
}
EOF

# Create Info.plist
cat > Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>Norio</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <false/>
        <key>UISceneConfigurations</key>
        <dict>
            <key>UIWindowSceneSessionRoleApplication</key>
            <array>
                <dict>
                    <key>UISceneConfigurationName</key>
                    <string>Default Configuration</string>
                    <key>UISceneDelegateClassName</key>
                    <string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>
                    <key>UISceneStoryboardFile</key>
                    <string>Main</string>
                </dict>
            </array>
        </dict>
    </dict>
    <key>UIApplicationSupportsIndirectInputEvents</key>
    <true/>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>armv7</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
</dict>
</plist>
EOF

cd ..

echo "✅ iOS app structure created!"
echo ""
echo "🎯 NEXT STEPS - Add NorioUI Package in Xcode:"
echo "=============================================="
echo ""
echo "1. Create New iOS Project:"
echo "   • Open Xcode"
echo "   • File > New > Project"
echo "   • iOS > App"
echo "   • Product Name: Norio"
echo "   • Bundle ID: com.norio.browser"
echo "   • Language: Swift, Interface: SwiftUI"
echo ""
echo "2. Add Local Package Dependency:"
echo "   • File > Add Package Dependencies"
echo "   • Click 'Add Local...'"
echo "   • Navigate to: $(pwd)"
echo "   • Select this directory and click 'Add Package'"
echo "   • Check: NorioUI, NorioCore, NorioExtensions"
echo "   • Click 'Add Package'"
echo ""
echo "3. Update ContentView.swift:"
echo "   • Add: import NorioUI"
echo "   • Replace body with: BrowserView()"
echo ""
echo "4. Copy files (if needed):"
echo "   • Copy NorioiOS/App.swift to replace your App.swift"
echo "   • Copy NorioiOS/Info.plist settings if needed"
echo ""
echo "📱 Example ContentView.swift after setup:"
echo "=========================================="
echo "import SwiftUI"
echo "import NorioUI"
echo ""
echo "struct ContentView: View {"
echo "    var body: some View {"
echo "        BrowserView()"
echo "    }"
echo "}"
echo ""
echo "🎉 Your iOS browser will be ready to run!" 