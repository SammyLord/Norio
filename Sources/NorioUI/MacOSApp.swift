#if os(macOS)
import SwiftUI
import NorioCore
import NorioExtensions

// This file is no longer the main entry point
// The @main attribute has been moved to AppEntry.swift
public struct NorioMacOSApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            BrowserView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            // File menu
            CommandGroup(replacing: .newItem) {
                Button("New Tab") {
                    NotificationCenter.default.post(name: NSNotification.Name("NewTab"), object: nil)
                }
                .keyboardShortcut("t", modifiers: .command)
                
                Button("New Window") {
                    NSApp.sendAction(#selector(NSDocumentController.newDocument(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Divider()
                
                Button("Open Location...") {
                    NotificationCenter.default.post(name: NSNotification.Name("FocusAddressBar"), object: nil)
                }
                .keyboardShortcut("l", modifiers: .command)
                
                Divider()
                
                Button("Close Tab") {
                    NotificationCenter.default.post(name: NSNotification.Name("CloseTab"), object: nil)
                }
                .keyboardShortcut("w", modifiers: .command)
                
                Button("Close Window") {
                    NSApp.keyWindow?.close()
                }
                .keyboardShortcut("w", modifiers: [.command, .shift])
            }
            
            // Edit menu
            CommandGroup(after: .pasteboard) {
                Button("Find...") {
                    NotificationCenter.default.post(name: NSNotification.Name("Find"), object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)
            }
            
            // View menu
            CommandGroup(before: .sidebar) {
                Button("Reload Page") {
                    NotificationCenter.default.post(name: NSNotification.Name("ReloadPage"), object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
                
                Button("Show Developer Tools") {
                    NotificationCenter.default.post(name: NSNotification.Name("ShowDeveloperTools"), object: nil)
                }
                .keyboardShortcut("i", modifiers: [.command, .option])
                
                Divider()
                
                Button("Zoom In") {
                    NotificationCenter.default.post(name: NSNotification.Name("ZoomIn"), object: nil)
                }
                .keyboardShortcut("+", modifiers: .command)
                
                Button("Zoom Out") {
                    NotificationCenter.default.post(name: NSNotification.Name("ZoomOut"), object: nil)
                }
                .keyboardShortcut("-", modifiers: .command)
                
                Button("Actual Size") {
                    NotificationCenter.default.post(name: NSNotification.Name("ResetZoom"), object: nil)
                }
                .keyboardShortcut("0", modifiers: .command)
            }
            
            // History menu
            CommandMenu("History") {
                Button("Back") {
                    NotificationCenter.default.post(name: NSNotification.Name("GoBack"), object: nil)
                }
                .keyboardShortcut("[", modifiers: .command)
                
                Button("Forward") {
                    NotificationCenter.default.post(name: NSNotification.Name("GoForward"), object: nil)
                }
                .keyboardShortcut("]", modifiers: .command)
                
                Divider()
                
                Button("Show History") {
                    NotificationCenter.default.post(name: NSNotification.Name("ShowHistory"), object: nil)
                }
                .keyboardShortcut("y", modifiers: .command)
            }
            
            // Bookmarks menu
            CommandMenu("Bookmarks") {
                Button("Bookmark This Page") {
                    NotificationCenter.default.post(name: NSNotification.Name("BookmarkPage"), object: nil)
                }
                .keyboardShortcut("d", modifiers: .command)
                
                Button("Show Bookmarks") {
                    NotificationCenter.default.post(name: NSNotification.Name("ShowBookmarks"), object: nil)
                }
                .keyboardShortcut("b", modifiers: .command)
            }
            
            // Extensions menu
            CommandMenu("Extensions") {
                Button("Manage Extensions") {
                    NotificationCenter.default.post(name: NSNotification.Name("ManageExtensions"), object: nil)
                }
                
                Divider()
                
                // The actual extensions will be populated dynamically by the AppDelegate
                Text("Installed Extensions")
                    .disabled(true)
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup code here
        setupExtensionMenu()
        initializeContentBlocker()
        
        // Register for notifications
        NotificationCenter.default.addObserver(self, selector: #selector(handleManageExtensions), name: NSNotification.Name("ManageExtensions"), object: nil)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    // Set up the dynamic extension menu
    private func setupExtensionMenu() {
        DispatchQueue.main.async {
            // Find the Extensions menu
            if let appMenu = NSApp.mainMenu,
               let extensionMenu = appMenu.items.first(where: { $0.title == "Extensions" })?.submenu {
                
                // Clear existing extension items (keeping the header items)
                while extensionMenu.items.count > 2 {
                    extensionMenu.removeItem(at: 2)
                }
                
                // Get installed extensions
                let extensions = ExtensionManager.shared.getInstalledExtensions()
                
                if !extensions.isEmpty {
                    extensionMenu.addItem(NSMenuItem.separator())
                    
                    // Add each extension to the menu
                    for ext in extensions {
                        let menuItem = NSMenuItem(title: ext.name, action: #selector(self.handleExtensionAction(_:)), keyEquivalent: "")
                        menuItem.target = self
                        menuItem.representedObject = ext.id
                        
                        // Set an image based on the extension type
                        if ext.type == .chrome {
                            menuItem.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "Chrome Extension")
                        } else {
                            menuItem.image = NSImage(systemSymbolName: "flame.fill", accessibilityDescription: "Firefox Extension")
                        }
                        
                        extensionMenu.addItem(menuItem)
                    }
                } else {
                    // Add a "No Extensions Installed" item
                    let menuItem = NSMenuItem(title: "No Extensions Installed", action: nil, keyEquivalent: "")
                    menuItem.isEnabled = false
                    extensionMenu.addItem(menuItem)
                }
            }
        }
    }
    
    @objc private func handleExtensionAction(_ sender: NSMenuItem) {
        if let extensionId = sender.representedObject as? String,
           let extensionItem = ExtensionManager.shared.getInstalledExtensions().first(where: { $0.id == extensionId }) {
            ExtensionManager.shared.runExtensionAction(extensionItem)
        }
    }
    
    @objc private func handleManageExtensions() {
        NotificationCenter.default.post(name: NSNotification.Name("ShowExtensions"), object: nil)
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
}
#endif 