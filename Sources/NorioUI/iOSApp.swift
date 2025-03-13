import SwiftUI
import NorioCore
import NorioExtensions

#if os(iOS)
@main
public struct NorioiOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            BrowserView()
                .edgesIgnoringSafeArea(.bottom)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
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
            ContentBlocker.shared.getAvailableBlockLists()
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

// iPad-specific optimizations
#if targetEnvironment(macCatalyst)
extension UIApplication {
    override open func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)
        
        // Add custom menu items for iPad
        if builder.system == .main {
            let newTabCommand = UIKeyCommand(
                title: "New Tab",
                image: nil,
                action: #selector(AppDelegate.newTab),
                input: "t",
                modifierFlags: .command
            )
            
            let fileMenu = UIMenu(
                title: "File",
                image: nil,
                children: [newTabCommand]
            )
            
            builder.insertChild(fileMenu, atStartOfMenu: .file)
            
            // Add Extensions menu
            let extensionsMenu = createExtensionsMenu()
            builder.insertSibling(extensionsMenu, afterMenu: .view)
        }
    }
    
    private func createExtensionsMenu() -> UIMenu {
        let manageExtensions = UICommand(
            title: "Manage Extensions...",
            image: UIImage(systemName: "gear"),
            action: #selector(AppDelegate.manageExtensions)
        )
        
        // Get installed extensions
        let extensions = ExtensionManager.shared.getInstalledExtensions()
        var extensionCommands: [UIMenuElement] = [manageExtensions, UIMenu.Separator()]
        
        for ext in extensions {
            let command = UICommand(
                title: ext.name,
                image: UIImage(systemName: ext.type == .chrome ? "globe" : "flame.fill"),
                action: #selector(AppDelegate.runExtension(_:)),
                propertyList: ext.id
            )
            extensionCommands.append(command)
        }
        
        return UIMenu(title: "Extensions", children: extensionCommands)
    }
}

extension AppDelegate {
    @objc func newTab() {
        NotificationCenter.default.post(name: NSNotification.Name("NewTab"), object: nil)
    }
    
    @objc func manageExtensions() {
        NotificationCenter.default.post(name: NSNotification.Name("ShowExtensions"), object: nil)
    }
    
    @objc func runExtension(_ sender: UICommand) {
        if let extensionId = sender.propertyList as? String,
           let extensionItem = ExtensionManager.shared.getInstalledExtensions().first(where: { $0.id == extensionId }) {
            ExtensionManager.shared.runExtensionAction(extensionItem)
        }
    }
}
#endif
#endif 