import Foundation
import WebKit
import Combine
import NorioCore

public class ExtensionManager {
    public static let shared = ExtensionManager()
    
    // Base URLs for extension stores
    public static let chromeWebStoreBaseURL = "https://chrome.google.com/webstore/detail/"
    public static let firefoxAddonsBaseURL = "https://addons.mozilla.org/en-US/firefox/addon/"
    
    // Extension types
    public enum ExtensionType: String, Codable {
        case chrome
        case firefox
    }
    
    // Extension data model
    public struct Extension: Identifiable, Codable {
        public let id: String
        public let name: String
        public let description: String
        public let version: String
        public let type: ExtensionType
        public var enabled: Bool
        public let manifestJson: [String: Any]
        public let entryPoints: [String]?
        public let contentScripts: [ContentScript]
        public let permissions: [String]
        public let optionalPermissions: [String]
        public let installDate: Date
        
        public init(id: String, name: String, description: String, version: String, type: ExtensionType, 
                   enabled: Bool = true, manifestJson: [String: Any], entryPoints: [String]?, contentScripts: [ContentScript],
                   permissions: [String], optionalPermissions: [String]) {
            self.id = id
            self.name = name
            self.description = description
            self.version = version
            self.type = type
            self.enabled = enabled
            self.manifestJson = manifestJson
            self.entryPoints = entryPoints
            self.contentScripts = contentScripts
            self.permissions = permissions
            self.optionalPermissions = optionalPermissions
            self.installDate = Date()
        }
        
        enum CodingKeys: String, CodingKey {
            case id, name, description, version, type, enabled, manifestJson, entryPoints,
                 contentScripts, permissions, optionalPermissions, installDate
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            name = try container.decode(String.self, forKey: .name)
            description = try container.decode(String.self, forKey: .description)
            version = try container.decode(String.self, forKey: .version)
            type = try container.decode(ExtensionType.self, forKey: .type)
            enabled = try container.decode(Bool.self, forKey: .enabled)
            
            // Decode the manifest JSON from a Data object
            let manifestData = try container.decode(Data.self, forKey: .manifestJson)
            if let json = try JSONSerialization.jsonObject(with: manifestData) as? [String: Any] {
                manifestJson = json
            } else {
                manifestJson = [:]
            }
            
            entryPoints = try container.decodeIfPresent([String].self, forKey: .entryPoints)
            contentScripts = try container.decode([ContentScript].self, forKey: .contentScripts)
            permissions = try container.decode([String].self, forKey: .permissions)
            optionalPermissions = try container.decode([String].self, forKey: .optionalPermissions)
            installDate = try container.decode(Date.self, forKey: .installDate)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encode(description, forKey: .description)
            try container.encode(version, forKey: .version)
            try container.encode(type, forKey: .type)
            try container.encode(enabled, forKey: .enabled)
            
            // Encode the manifest JSON to a Data object
            let manifestData = try JSONSerialization.data(withJSONObject: manifestJson)
            try container.encode(manifestData, forKey: .manifestJson)
            
            try container.encodeIfPresent(entryPoints, forKey: .entryPoints)
            try container.encode(contentScripts, forKey: .contentScripts)
            try container.encode(permissions, forKey: .permissions)
            try container.encode(optionalPermissions, forKey: .optionalPermissions)
            try container.encode(installDate, forKey: .installDate)
        }
    }
    
    // Content script model
    public struct ContentScript: Codable {
        public let js: [String]
        public let css: [String]
        public let matches: [String]
        public let runAt: RunAt
        
        public enum RunAt: String, Codable {
            case documentStart = "document_start"
            case documentEnd = "document_end"
            case documentIdle = "document_idle"
        }
    }
    
    // Private properties
    private var installedExtensions: [Extension] = []
    private let extensionsDirectory: URL
    private var extensionObservers = Set<AnyCancellable>()
    private let notificationCenter = NotificationCenter.default
    
    // Public notifications
    public static let extensionsUpdatedNotification = Notification.Name("ExtensionManagerExtensionsUpdated")
    
    // Private initializer
    private init() {
        // Create the extensions directory if it doesn't exist
        let fileManager = FileManager.default
        let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let norioDirectory = appSupportDirectory.appendingPathComponent("Norio", isDirectory: true)
        extensionsDirectory = norioDirectory.appendingPathComponent("Extensions", isDirectory: true)
        
        try? fileManager.createDirectory(at: extensionsDirectory, withIntermediateDirectories: true)
        
        // Load installed extensions
        loadInstalledExtensions()
    }
    
    // MARK: - Public Methods
    
    /// Returns a list of all installed extensions
    public func getInstalledExtensions() -> [Extension] {
        return installedExtensions
    }
    
    /// Enables or disables an extension
    public func setExtensionEnabled(_ extensionId: String, enabled: Bool) {
        guard let index = installedExtensions.firstIndex(where: { $0.id == extensionId }) else { return }
        
        installedExtensions[index].enabled = enabled
        
        // Save changes
        saveInstalledExtensions()
        
        // Notify observers
        notificationCenter.post(name: Self.extensionsUpdatedNotification, object: nil)
    }
    
    /// Removes an extension
    public func removeExtension(_ extensionId: String) {
        guard let index = installedExtensions.firstIndex(where: { $0.id == extensionId }) else { return }
        
        // Save the name before removal
        let extensionName = installedExtensions[index].name
        
        // Get the extension directory
        let extensionDirectory = extensionsDirectory.appendingPathComponent(extensionId, isDirectory: true)
        
        // Remove the extension files
        try? FileManager.default.removeItem(at: extensionDirectory)
        
        // Remove from the list
        installedExtensions.remove(at: index)
        
        // Save changes
        saveInstalledExtensions()
        
        // Notify observers
        notificationCenter.post(name: Self.extensionsUpdatedNotification, object: nil)
        
        // Show notification
        NotificationManager.shared.showExtensionRemoved(name: extensionName)
    }
    
    /// Runs an extension action
    public func runExtensionAction(_ extension: Extension) {
        guard `extension`.enabled else { return }
        
        // In a real implementation, this would trigger the extension's background page or action
        Logger.shared.log("Running extension action: \(`extension`.name)")
        
        // For now, just show a notification that the extension was triggered
        NotificationManager.shared.showNotification(
            title: "Extension Action",
            message: "Triggered \(`extension`.name)"
        )
    }
    
    /// Applies extensions to a WebView
    public func applyExtensionsToWebView(_ webView: WKWebView) {
        // Only apply enabled extensions
        let enabledExtensions = installedExtensions.filter { $0.enabled }
        
        for ext in enabledExtensions {
            applyExtension(ext, toWebView: webView)
        }
    }
    
    // MARK: - Chrome Extension Installation
    
    /// Installs a Chrome extension from a URL
    public func installChromeExtension(from url: URL, completion: @escaping (Result<Extension, Error>) -> Void) {
        // For Chrome extensions, we expect a .crx file
        guard url.pathExtension.lowercased() == "crx" else {
            completion(.failure(ExtensionError.invalidFileFormat("Expected .crx file")))
            return
        }
        
        // Download the extension file
        URLSession.shared.downloadTask(with: url) { tempURL, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let tempURL = tempURL else {
                DispatchQueue.main.async {
                    completion(.failure(ExtensionError.downloadFailed))
                }
                return
            }
            
            // Process the .crx file
            self.processChromeExtension(tempURL) { result in
                DispatchQueue.main.async {
                    completion(result)
                }
            }
        }.resume()
    }
    
    /// Installs a Chrome extension from the Chrome Web Store
    public func installChromeExtensionFromStore(id: String, completion: @escaping (Result<Extension, Error>) -> Void) {
        // In a real implementation, this would fetch the extension from the Chrome Web Store
        // For this demo, we'll create a simulated extension
        
        let extensionDir = extensionsDirectory.appendingPathComponent(id, isDirectory: true)
        
        // Create directory for this extension
        try? FileManager.default.createDirectory(at: extensionDir, withIntermediateDirectories: true)
        
        // Create a simulated manifest.json
        let manifestDict: [String: Any] = [
            "name": "Chrome Extension \(id.prefix(6))",
            "description": "A simulated Chrome extension",
            "version": "1.0.0",
            "manifest_version": 2,
            "permissions": ["tabs", "storage"],
            "content_scripts": [
                [
                    "matches": ["*://*/*"],
                    "js": ["content.js"],
                    "run_at": "document_end"
                ]
            ]
        ]
        
        // Write manifest.json
        let manifestURL = extensionDir.appendingPathComponent("manifest.json")
        if let manifestData = try? JSONSerialization.data(withJSONObject: manifestDict) {
            try? manifestData.write(to: manifestURL)
        }
        
        // Create a simple content script
        let contentJS = """
        // Content script for Chrome extension \(id)
        console.log('Chrome extension \(id) injected');
        document.body.style.border = '5px solid blue';
        """
        
        let contentJSURL = extensionDir.appendingPathComponent("content.js")
        try? contentJS.write(to: contentJSURL, atomically: true, encoding: .utf8)
        
        // Create the Extension object
        let contentScript = ContentScript(
            js: ["content.js"],
            css: [],
            matches: ["*://*/*"],
            runAt: .documentEnd
        )
        
        let extensionName = "Chrome Extension \(id.prefix(6))"
        let extensionObj = Extension(
            id: id,
            name: extensionName,
            description: "A simulated Chrome extension",
            version: "1.0.0",
            type: .chrome,
            enabled: true,
            manifestJson: manifestDict,
            entryPoints: nil,
            contentScripts: [contentScript],
            permissions: ["tabs", "storage"],
            optionalPermissions: []
        )
        
        // Add to installed extensions
        self.installedExtensions.append(extensionObj)
        self.saveInstalledExtensions()
        
        // Notify observers
        self.notificationCenter.post(name: Self.extensionsUpdatedNotification, object: nil)
        
        // Show notification
        NotificationManager.shared.showExtensionInstalled(name: extensionName, type: .chrome)
        
        completion(.success(extensionObj))
    }
    
    // MARK: - Firefox Extension Installation
    
    /// Installs a Firefox extension from a URL
    public func installFirefoxExtension(from url: URL, completion: @escaping (Result<Extension, Error>) -> Void) {
        // For Firefox extensions, we expect a .xpi file
        guard url.pathExtension.lowercased() == "xpi" else {
            completion(.failure(ExtensionError.invalidFileFormat("Expected .xpi file")))
            return
        }
        
        // Download the extension file
        URLSession.shared.downloadTask(with: url) { tempURL, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let tempURL = tempURL else {
                DispatchQueue.main.async {
                    completion(.failure(ExtensionError.downloadFailed))
                }
                return
            }
            
            // Process the .xpi file
            self.processFirefoxExtension(tempURL) { result in
                DispatchQueue.main.async {
                    completion(result)
                }
            }
        }.resume()
    }
    
    /// Installs a Firefox extension from the Firefox Add-ons site
    public func installFirefoxExtensionFromStore(id: String, completion: @escaping (Result<Extension, Error>) -> Void) {
        // In a real implementation, this would fetch the extension from the Firefox Add-ons site
        // For this demo, we'll create a simulated extension
        
        let extensionDir = extensionsDirectory.appendingPathComponent(id, isDirectory: true)
        
        // Create directory for this extension
        try? FileManager.default.createDirectory(at: extensionDir, withIntermediateDirectories: true)
        
        // Create a simulated manifest.json
        let manifestDict: [String: Any] = [
            "name": "Firefox Add-on \(id)",
            "description": "A simulated Firefox add-on",
            "version": "1.0.0",
            "manifest_version": 2,
            "permissions": ["tabs", "storage"],
            "content_scripts": [
                [
                    "matches": ["*://*/*"],
                    "js": ["content.js"],
                    "run_at": "document_end"
                ]
            ]
        ]
        
        // Write manifest.json
        let manifestURL = extensionDir.appendingPathComponent("manifest.json")
        if let manifestData = try? JSONSerialization.data(withJSONObject: manifestDict) {
            try? manifestData.write(to: manifestURL)
        }
        
        // Create a simple content script
        let contentJS = """
        // Content script for Firefox add-on \(id)
        console.log('Firefox add-on \(id) injected');
        document.body.style.border = '5px solid orange';
        """
        
        let contentJSURL = extensionDir.appendingPathComponent("content.js")
        try? contentJS.write(to: contentJSURL, atomically: true, encoding: .utf8)
        
        // Create the Extension object
        let contentScript = ContentScript(
            js: ["content.js"],
            css: [],
            matches: ["*://*/*"],
            runAt: .documentEnd
        )
        
        let extensionName = "Firefox Add-on \(id)"
        let extensionObj = Extension(
            id: id,
            name: extensionName,
            description: "A simulated Firefox add-on",
            version: "1.0.0",
            type: .firefox,
            enabled: true,
            manifestJson: manifestDict,
            entryPoints: nil,
            contentScripts: [contentScript],
            permissions: ["tabs", "storage"],
            optionalPermissions: []
        )
        
        // Add to installed extensions
        self.installedExtensions.append(extensionObj)
        self.saveInstalledExtensions()
        
        // Notify observers
        self.notificationCenter.post(name: Self.extensionsUpdatedNotification, object: nil)
        
        // Show notification
        NotificationManager.shared.showExtensionInstalled(name: extensionName, type: .firefox)
        
        completion(.success(extensionObj))
    }
    
    // MARK: - Private Methods
    
    /// Loads installed extensions from disk
    private func loadInstalledExtensions() {
        let extensionsDataURL = extensionsDirectory.appendingPathComponent("extensions.json")
        
        if let data = try? Data(contentsOf: extensionsDataURL),
           let extensions = try? JSONDecoder().decode([Extension].self, from: data) {
            installedExtensions = extensions
        }
    }
    
    /// Saves installed extensions to disk
    private func saveInstalledExtensions() {
        let extensionsDataURL = extensionsDirectory.appendingPathComponent("extensions.json")
        
        if let data = try? JSONEncoder().encode(installedExtensions) {
            try? data.write(to: extensionsDataURL)
        }
    }
    
    /// Processes a Chrome extension file
    private func processChromeExtension(_ url: URL, completion: @escaping (Result<Extension, Error>) -> Void) {
        // In a real implementation, this would extract the .crx file and parse the manifest
        // For this demo, we'll just simulate success
        
        let id = UUID().uuidString
        let extensionObj = Extension(
            id: id,
            name: "Chrome Extension",
            description: "A Chrome extension",
            version: "1.0.0",
            type: .chrome,
            enabled: true,
            manifestJson: [:],
            entryPoints: nil,
            contentScripts: [],
            permissions: [],
            optionalPermissions: []
        )
        
        // Add to installed extensions
        installedExtensions.append(extensionObj)
        saveInstalledExtensions()
        
        // Notify observers
        notificationCenter.post(name: Self.extensionsUpdatedNotification, object: nil)
        
        completion(.success(extensionObj))
    }
    
    /// Processes a Firefox extension file
    private func processFirefoxExtension(_ url: URL, completion: @escaping (Result<Extension, Error>) -> Void) {
        // In a real implementation, this would extract the .xpi file and parse the manifest
        // For this demo, we'll just simulate success
        
        let id = UUID().uuidString
        let extensionObj = Extension(
            id: id,
            name: "Firefox Add-on",
            description: "A Firefox add-on",
            version: "1.0.0",
            type: .firefox,
            enabled: true,
            manifestJson: [:],
            entryPoints: nil,
            contentScripts: [],
            permissions: [],
            optionalPermissions: []
        )
        
        // Add to installed extensions
        installedExtensions.append(extensionObj)
        saveInstalledExtensions()
        
        // Notify observers
        notificationCenter.post(name: Self.extensionsUpdatedNotification, object: nil)
        
        completion(.success(extensionObj))
    }
    
    /// Applies an extension to a WebView
    private func applyExtension(_ extension: Extension, toWebView webView: WKWebView) {
        guard `extension`.enabled else { return }
        
        // Apply content scripts
        for contentScript in `extension`.contentScripts {
            applyContentScript(contentScript, from: `extension`, toWebView: webView)
        }
    }
    
    /// Applies a content script to a WebView
    private func applyContentScript(_ contentScript: ContentScript, from extension: Extension, toWebView webView: WKWebView) {
        // Get the extension directory
        let extensionDirectory = extensionsDirectory.appendingPathComponent(`extension`.id, isDirectory: true)
        
        // Add JavaScript files
        for jsFile in contentScript.js {
            let jsURL = extensionDirectory.appendingPathComponent(jsFile)
            
            if let jsContent = try? String(contentsOf: jsURL) {
                let userScript = WKUserScript(
                    source: jsContent,
                    injectionTime: contentScriptInjectionTime(contentScript.runAt),
                    forMainFrameOnly: false
                )
                
                webView.configuration.userContentController.addUserScript(userScript)
            }
        }
        
        // Add CSS files
        for cssFile in contentScript.css {
            let cssURL = extensionDirectory.appendingPathComponent(cssFile)
            
            if let cssContent = try? String(contentsOf: cssURL) {
                // Wrap CSS in JavaScript that injects it
                let jsWrapper = """
                (function() {
                    var style = document.createElement('style');
                    style.textContent = `\(cssContent)`;
                    document.head.appendChild(style);
                })();
                """
                
                let userScript = WKUserScript(
                    source: jsWrapper,
                    injectionTime: contentScriptInjectionTime(contentScript.runAt),
                    forMainFrameOnly: false
                )
                
                webView.configuration.userContentController.addUserScript(userScript)
            }
        }
    }
    
    /// Converts a content script run_at value to a WKUserScriptInjectionTime
    private func contentScriptInjectionTime(_ runAt: ContentScript.RunAt) -> WKUserScriptInjectionTime {
        switch runAt {
        case .documentStart:
            return .atDocumentStart
        case .documentEnd, .documentIdle:
            return .atDocumentEnd
        }
    }
}

// Extension errors
enum ExtensionError: Error {
    case invalidFileFormat(String)
    case downloadFailed
    case extractionFailed
    case invalidManifest
    case missingRequiredFields
    case incompatibleExtension
} 