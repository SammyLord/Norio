import Foundation

#if os(macOS)
import AppKit
#else
import UIKit
#endif

public class DefaultBrowserManager {
    public static let shared = DefaultBrowserManager()
    
    private init() {}

    public func isDefaultBrowser() -> Bool {
        #if os(macOS)
        guard let httpUrl = URL(string: "http://example.com"),
              let defaultAppURL = NSWorkspace.shared.urlForApplication(toOpen: httpUrl) else {
            return false
        }
        return defaultAppURL == Bundle.main.bundleURL
        #else
        // It's not possible to check this on iOS.
        return false
        #endif
    }

    public func openDefaultBrowserSettings() {
        #if os(macOS)
        let urlString: String
        if ProcessInfo.processInfo.isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 13, minorVersion: 0, patchVersion: 0)) {
            urlString = "x-apple.systempreferences:com.apple.Desktop-Dock-Settings.extension"
        } else {
            urlString = "x-apple.systempreferences:com.apple.preference.general"
        }
        
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
        #elseif os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }
} 