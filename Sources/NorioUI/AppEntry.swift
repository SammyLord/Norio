import SwiftUI
import NorioCore
import NorioExtensions

// This file serves as the single entry point for the app
// It conditionally imports the appropriate app struct based on the platform

#if os(iOS)
public struct NorioiOS: App {
    @UIApplicationDelegateAdaptor(iOSAppDelegate.self) private var appDelegate
    
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            BrowserView()
                .edgesIgnoringSafeArea(.bottom)
        }
    }
}

// iOS App Delegate
class iOSAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Setup code here
        setupExtensionSystem()
        initializeContentBlocker()
        return true
    }
    
    private func setupExtensionSystem() {
        // Load extensions when app starts
        _ = ExtensionManager.shared.getInstalledExtensions()
        
        // Setup extension-related notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleExtensionAction(_:)),
            name: NSNotification.Name("RunExtensionAction"),
            object: nil
        )
    }
    
    // Initialize the content blocker
    private func initializeContentBlocker() {
        // Load content blocker rules in background
        DispatchQueue.global(qos: .background).async {
            let enabled = UserDefaults.standard.object(forKey: "ContentBlockingEnabled") as? Bool ?? true
            BrowserEngine.shared.contentBlockingEnabled = enabled
            
            // Force load the block lists
            _ = ContentBlocker.shared.getAvailableBlockLists()
        }
    }
    
    @objc private func handleExtensionAction(_ notification: Notification) {
        if let extensionId = notification.userInfo?["extensionId"] as? String,
           let extensionItem = ExtensionManager.shared.getInstalledExtensions().first(where: { $0.id == extensionId }) {
            ExtensionManager.shared.runExtensionAction(extensionItem)
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // Handle URL opening
        NotificationCenter.default.post(name: NSNotification.Name("OpenURL"), object: url)
        
        // Handle extension installation if it's a .crx or .xpi file
        if url.pathExtension == "crx" {
            ExtensionManager.shared.installChromeExtension(from: url) { _ in }
            return true
        } else if url.pathExtension == "xpi" {
            ExtensionManager.shared.installFirefoxExtension(from: url) { _ in }
            return true
        }
        
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        // Handle universal links
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL {
            NotificationCenter.default.post(name: NSNotification.Name("OpenURL"), object: url)
            return true
        }
        return false
    }
}

#elseif os(macOS)
public struct NorioMac: App {
    @NSApplicationDelegateAdaptor(MacAppDelegate.self) private var appDelegate
    
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            BrowserView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Tab") {
                    NotificationCenter.default.post(name: NSNotification.Name("NewTab"), object: nil)
                }
                .keyboardShortcut("t", modifiers: .command)
                
                Button("New Window") {
                    NotificationCenter.default.post(name: NSNotification.Name("NewWindow"), object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
            
            CommandGroup(replacing: .undoRedo) {}
            
            CommandGroup(replacing: .pasteboard) {}
            
            CommandGroup(after: .windowList) {
                Button("Extensions") {
                    NotificationCenter.default.post(name: NSNotification.Name("ShowExtensions"), object: nil)
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
            }
        }
    }
}

// macOS App Delegate
class MacAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup code here
        setupExtensionSystem()
        initializeContentBlocker()
        setupExtensionMenu()
    }
    
    private func setupExtensionSystem() {
        // Load extensions when app starts
        _ = ExtensionManager.shared.getInstalledExtensions()
        
        // Setup extension-related notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleExtensionAction(_:)),
            name: NSNotification.Name("RunExtensionAction"),
            object: nil
        )
    }
    
    // Initialize the content blocker
    private func initializeContentBlocker() {
        // Load content blocker rules in background
        DispatchQueue.global(qos: .background).async {
            let enabled = UserDefaults.standard.object(forKey: "ContentBlockingEnabled") as? Bool ?? true
            BrowserEngine.shared.contentBlockingEnabled = enabled
            
            // Force load the block lists
            _ = ContentBlocker.shared.getAvailableBlockLists()
        }
    }
    
    private func setupExtensionMenu() {
        // Create dynamic extension menu
        let extensionsMenu = NSMenu(title: "Extensions")
        extensionsMenu.addItem(NSMenuItem(title: "Manage Extensions...", action: #selector(manageExtensions), keyEquivalent: "E"))
        
        // Add separator
        extensionsMenu.addItem(NSMenuItem.separator())
        
        // Add installed extensions
        for ext in ExtensionManager.shared.getInstalledExtensions() {
            let item = NSMenuItem(title: ext.name, action: #selector(runExtension(_:)), keyEquivalent: "")
            item.representedObject = ext.id
            extensionsMenu.addItem(item)
        }
        
        // Add to main menu
        if let mainMenu = NSApp.mainMenu {
            let extensionsMenuItem = NSMenuItem(title: "Extensions", action: nil, keyEquivalent: "")
            extensionsMenuItem.submenu = extensionsMenu
            mainMenu.insertItem(extensionsMenuItem, at: 4) // After View menu
        }
    }
    
    @objc private func handleExtensionAction(_ notification: Notification) {
        if let extensionId = notification.userInfo?["extensionId"] as? String,
           let extensionItem = ExtensionManager.shared.getInstalledExtensions().first(where: { $0.id == extensionId }) {
            ExtensionManager.shared.runExtensionAction(extensionItem)
        }
    }
    
    @objc func manageExtensions() {
        NotificationCenter.default.post(name: NSNotification.Name("ShowExtensions"), object: nil)
    }
    
    @objc func runExtension(_ sender: NSMenuItem) {
        if let extensionId = sender.representedObject as? String,
           let extensionItem = ExtensionManager.shared.getInstalledExtensions().first(where: { $0.id == extensionId }) {
            ExtensionManager.shared.runExtensionAction(extensionItem)
        }
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            // Handle URL opening
            NotificationCenter.default.post(name: NSNotification.Name("OpenURL"), object: url)
            
            // Handle extension installation if it's a .crx or .xpi file
            if url.pathExtension == "crx" {
                ExtensionManager.shared.installChromeExtension(from: url) { _ in }
            } else if url.pathExtension == "xpi" {
                ExtensionManager.shared.installFirefoxExtension(from: url) { _ in }
            }
        }
    }
}
#endif 