import Foundation
import WebKit
import NorioCore

public class ExtensionManager {
    public static let shared = ExtensionManager()
    
    private var installedExtensions: [Extension] = []
    
    // Store URLs
    public static let chromeWebStoreBaseURL = "https://chrome.google.com/webstore/detail/"
    public static let firefoxAddonsBaseURL = "https://addons.mozilla.org/en-US/firefox/addon/"
    
    private init() {
        loadInstalledExtensions()
        
        // Add some sample extensions for testing
        if installedExtensions.isEmpty {
            addSampleExtensions()
        }
    }
    
    // Extension representation
    public struct Extension: Codable, Identifiable {
        public let id: String
        public let name: String
        public let version: String
        public let description: String
        public let type: ExtensionType
        public let enabled: Bool
        public let manifestPath: URL
        public let iconPath: URL?
        public let storeURL: URL?
        
        public init(id: String, name: String, version: String, description: String, type: ExtensionType, enabled: Bool = true, manifestPath: URL, iconPath: URL? = nil, storeURL: URL? = nil) {
            self.id = id
            self.name = name
            self.version = version
            self.description = description
            self.type = type
            self.enabled = enabled
            self.manifestPath = manifestPath
            self.iconPath = iconPath
            self.storeURL = storeURL
        }
    }
    
    public enum ExtensionType: String, Codable {
        case chrome
        case firefox
    }
    
    // Get all installed extensions
    public func getInstalledExtensions() -> [Extension] {
        return installedExtensions
    }
    
    // Add sample extensions for testing
    private func addSampleExtensions() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let chromeExtension1 = Extension(
            id: "aapbdbdomjkkjkaonfhkkikfgjllcleb",
            name: "Google Translate",
            version: "1.0.0",
            description: "View translations easily as you browse the web.",
            type: .chrome,
            enabled: true,
            manifestPath: documentsDirectory,
            iconPath: nil,
            storeURL: URL(string: "\(Self.chromeWebStoreBaseURL)aapbdbdomjkkjkaonfhkkikfgjllcleb")
        )
        
        let chromeExtension2 = Extension(
            id: "gcbommkclmclpchllfjekcdonpmejbdp",
            name: "HTTPS Everywhere",
            version: "2.0.1",
            description: "Encrypt the web! Automatically use HTTPS security on many sites.",
            type: .chrome,
            enabled: true,
            manifestPath: documentsDirectory,
            iconPath: nil,
            storeURL: URL(string: "\(Self.chromeWebStoreBaseURL)gcbommkclmclpchllfjekcdonpmejbdp")
        )
        
        let firefoxExtension = Extension(
            id: "ublock-origin@mozilla.org",
            name: "uBlock Origin",
            version: "1.41.8",
            description: "Finally, an efficient blocker. Easy on CPU and memory.",
            type: .firefox,
            enabled: true,
            manifestPath: documentsDirectory,
            iconPath: nil,
            storeURL: URL(string: "\(Self.firefoxAddonsBaseURL)ublock-origin")
        )
        
        installedExtensions.append(chromeExtension1)
        installedExtensions.append(chromeExtension2)
        installedExtensions.append(firefoxExtension)
    }
    
    // Load all installed extensions
    private func loadInstalledExtensions() {
        // Load from user defaults or file system
        let extensionsDirectory = getExtensionsDirectory()
        
        // Check if directory exists, if not create it
        if !FileManager.default.fileExists(atPath: extensionsDirectory.path) {
            try? FileManager.default.createDirectory(at: extensionsDirectory, withIntermediateDirectories: true)
        }
        
        // Load Chrome extensions
        let chromeExtensionsDirectory = extensionsDirectory.appendingPathComponent("Chrome")
        if !FileManager.default.fileExists(atPath: chromeExtensionsDirectory.path) {
            try? FileManager.default.createDirectory(at: chromeExtensionsDirectory, withIntermediateDirectories: true)
        }
        
        // Load Firefox extensions
        let firefoxExtensionsDirectory = extensionsDirectory.appendingPathComponent("Firefox")
        if !FileManager.default.fileExists(atPath: firefoxExtensionsDirectory.path) {
            try? FileManager.default.createDirectory(at: firefoxExtensionsDirectory, withIntermediateDirectories: true)
        }
        
        // TODO: Implement actual loading of extension manifests from directories
    }
    
    // Get the directory where extensions are stored
    private func getExtensionsDirectory() -> URL {
        let applicationSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return applicationSupportDirectory.appendingPathComponent("Norio").appendingPathComponent("Extensions")
    }
    
    // Install a Chrome extension
    public func installChromeExtension(from url: URL, completion: @escaping (Result<Extension, Error>) -> Void) {
        // TODO: Implement actual Chrome extension installation
        // 1. Download the .crx file
        // 2. Extract the contents
        // 3. Parse the manifest.json
        // 4. Create an Extension object
        // 5. Add to installed extensions
        completion(.failure(NSError(domain: "ExtensionManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Chrome extension installation not implemented yet"])))
    }
    
    // Install a Firefox extension
    public func installFirefoxExtension(from url: URL, completion: @escaping (Result<Extension, Error>) -> Void) {
        // TODO: Implement actual Firefox extension installation
        // 1. Download the .xpi file
        // 2. Extract the contents
        // 3. Parse the manifest.json
        // 4. Create an Extension object
        // 5. Add to installed extensions
        completion(.failure(NSError(domain: "ExtensionManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Firefox extension installation not implemented yet"])))
    }
    
    // Enable or disable an extension
    public func setExtensionEnabled(_ extensionId: String, enabled: Bool) {
        if let index = installedExtensions.firstIndex(where: { $0.id == extensionId }) {
            let ext = installedExtensions[index]
            installedExtensions[index] = Extension(
                id: ext.id,
                name: ext.name,
                version: ext.version,
                description: ext.description,
                type: ext.type,
                enabled: enabled,
                manifestPath: ext.manifestPath,
                iconPath: ext.iconPath,
                storeURL: ext.storeURL
            )
            
            // Save changes
            saveInstalledExtensions()
        }
    }
    
    // Remove an extension
    public func removeExtension(_ extensionId: String) {
        installedExtensions.removeAll { $0.id == extensionId }
        
        // TODO: Remove extension files from disk
        
        // Save changes
        saveInstalledExtensions()
    }
    
    // Save installed extensions to disk
    private func saveInstalledExtensions() {
        // TODO: Implement saving to user defaults or file system
    }
    
    // Apply extensions to a WebView
    public func applyExtensionsToWebView(_ webView: WKWebView) {
        for ext in installedExtensions where ext.enabled {
            applyExtension(ext, to: webView)
        }
    }
    
    // Apply a single extension to a WebView
    private func applyExtension(_ extension: Extension, to webView: WKWebView) {
        switch `extension`.type {
        case .chrome:
            applyChromeExtension(`extension`, to: webView)
        case .firefox:
            applyFirefoxExtension(`extension`, to: webView)
        }
    }
    
    // Apply a Chrome extension
    private func applyChromeExtension(_ extension: Extension, to webView: WKWebView) {
        // TODO: Implement Chrome extension application logic
        // 1. Read the manifest.json
        // 2. Load content scripts
        // 3. Inject appropriate scripts based on URL patterns
    }
    
    // Apply a Firefox extension
    private func applyFirefoxExtension(_ extension: Extension, to webView: WKWebView) {
        // TODO: Implement Firefox extension application logic
        // 1. Read the manifest.json
        // 2. Load content scripts
        // 3. Inject appropriate scripts based on URL patterns
    }
    
    // Run an extension action
    public func runExtensionAction(_ extension: Extension) {
        // This would typically open the extension's popup or execute its default action
        print("Running extension action for: \(`extension`.name)")
        // In a real implementation, this would show the extension's popup UI or execute its action
    }
    
    // MARK: - Web Store Installation
    
    /// Install an extension from Chrome Web Store by its ID
    public func installChromeExtensionFromStore(id: String, completion: @escaping (Result<Extension, Error>) -> Void) {
        let storeURL = URL(string: "\(Self.chromeWebStoreBaseURL)\(id)")!
        
        // First fetch extension metadata
        fetchChromeExtensionMetadata(id: id) { [weak self] result in
            switch result {
            case .success(let metadata):
                // Then download the extension file
                self?.downloadChromeExtension(id: id, metadata: metadata, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Install an extension from Firefox Add-ons by its ID
    public func installFirefoxExtensionFromStore(id: String, completion: @escaping (Result<Extension, Error>) -> Void) {
        let storeURL = URL(string: "\(Self.firefoxAddonsBaseURL)\(id)")!
        
        // First fetch extension metadata
        fetchFirefoxExtensionMetadata(id: id) { [weak self] result in
            switch result {
            case .success(let metadata):
                // Then download the extension file
                self?.downloadFirefoxExtension(id: id, metadata: metadata, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Fetch metadata for a Chrome extension
    private func fetchChromeExtensionMetadata(id: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        // In a real implementation, we would use Chrome Web Store API or scrape the page
        // For this demo, we'll simulate the metadata fetch
        let metadata: [String: Any] = [
            "name": "Chrome Extension \(id)",
            "version": "1.0.0",
            "description": "Extension from Chrome Web Store"
        ]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(.success(metadata))
        }
    }
    
    // Fetch metadata for a Firefox extension
    private func fetchFirefoxExtensionMetadata(id: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        // Firefox Add-ons has an API we can use: https://addons-server.readthedocs.io/en/latest/topics/api/addons.html
        // For this demo, we'll simulate the metadata fetch
        let metadata: [String: Any] = [
            "name": "Firefox Add-on \(id)",
            "version": "1.0.0",
            "description": "Add-on from Firefox Add-ons"
        ]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(.success(metadata))
        }
    }
    
    // Download a Chrome extension
    private func downloadChromeExtension(id: String, metadata: [String: Any], completion: @escaping (Result<Extension, Error>) -> Void) {
        // In a real implementation, we would download the .crx file
        // For this demo, we'll simulate the download and installation
        let name = metadata["name"] as? String ?? "Unknown"
        let version = metadata["version"] as? String ?? "1.0.0"
        let description = metadata["description"] as? String ?? "No description"
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let manifestPath = documentsDirectory.appendingPathComponent("\(id)/manifest.json")
        let storeURL = URL(string: "\(Self.chromeWebStoreBaseURL)\(id)")
        
        let extension = Extension(
            id: id,
            name: name,
            version: version,
            description: description,
            type: .chrome,
            enabled: true,
            manifestPath: manifestPath,
            iconPath: nil,
            storeURL: storeURL
        )
        
        // Add to installed extensions
        installedExtensions.append(extension)
        saveInstalledExtensions()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion(.success(extension))
        }
    }
    
    // Download a Firefox extension
    private func downloadFirefoxExtension(id: String, metadata: [String: Any], completion: @escaping (Result<Extension, Error>) -> Void) {
        // In a real implementation, we would download the .xpi file
        // For this demo, we'll simulate the download and installation
        let name = metadata["name"] as? String ?? "Unknown"
        let version = metadata["version"] as? String ?? "1.0.0"
        let description = metadata["description"] as? String ?? "No description"
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let manifestPath = documentsDirectory.appendingPathComponent("\(id)/manifest.json")
        let storeURL = URL(string: "\(Self.firefoxAddonsBaseURL)\(id)")
        
        let extension = Extension(
            id: id,
            name: name,
            version: version,
            description: description,
            type: .firefox,
            enabled: true,
            manifestPath: manifestPath,
            iconPath: nil,
            storeURL: storeURL
        )
        
        // Add to installed extensions
        installedExtensions.append(extension)
        saveInstalledExtensions()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion(.success(extension))
        }
    }
}

// Chrome extension manifest parser
extension ExtensionManager {
    struct ChromeManifest: Codable {
        let name: String
        let version: String
        let description: String?
        let permissions: [String]?
        let background: Background?
        let contentScripts: [ContentScript]?
        let browserAction: BrowserAction?
        
        enum CodingKeys: String, CodingKey {
            case name, version, description, permissions, background
            case contentScripts = "content_scripts"
            case browserAction = "browser_action"
        }
        
        struct Background: Codable {
            let scripts: [String]?
            let page: String?
        }
        
        struct ContentScript: Codable {
            let matches: [String]
            let js: [String]?
            let css: [String]?
            let runAt: String?
            
            enum CodingKeys: String, CodingKey {
                case matches
                case js = "js"
                case css = "css"
                case runAt = "run_at"
            }
        }
        
        struct BrowserAction: Codable {
            let default_icon: [String: String]?
            let default_title: String?
            let default_popup: String?
        }
    }
}

// Firefox extension manifest parser
extension ExtensionManager {
    struct FirefoxManifest: Codable {
        let name: String
        let version: String
        let description: String?
        let permissions: [String]?
        let background: Background?
        let contentScripts: [ContentScript]?
        let browserAction: BrowserAction?
        
        enum CodingKeys: String, CodingKey {
            case name, version, description, permissions, background
            case contentScripts = "content_scripts"
            case browserAction = "browser_action"
        }
        
        struct Background: Codable {
            let scripts: [String]?
            let page: String?
        }
        
        struct ContentScript: Codable {
            let matches: [String]
            let js: [String]?
            let css: [String]?
            let runAt: String?
            
            enum CodingKeys: String, CodingKey {
                case matches
                case js = "js"
                case css = "css"
                case runAt = "run_at"
            }
        }
        
        struct BrowserAction: Codable {
            let default_icon: [String: String]?
            let default_title: String?
            let default_popup: String?
        }
    }
} 