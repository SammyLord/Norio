import XCTest
import Combine
import NorioCore
@testable import NorioExtensions

final class ExtensionManagerTests: XCTestCase {
    var extensionManager: ExtensionManager!
    
    override func setUp() {
        super.setUp()
        extensionManager = ExtensionManager.shared
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testExtensionManagerInitialization() {
        XCTAssertNotNil(extensionManager, "ExtensionManager should not be nil")
    }
    
    func testBaseURLs() {
        XCTAssertEqual(ExtensionManager.chromeWebStoreBaseURL, "https://chrome.google.com/webstore/detail/", "Chrome Web Store base URL should match")
        XCTAssertEqual(ExtensionManager.firefoxAddonsBaseURL, "https://addons.mozilla.org/en-US/firefox/addon/", "Firefox Add-ons base URL should match")
    }
    
    func testExtensionType() {
        XCTAssertEqual(ExtensionType.chrome.rawValue, "chrome")
        XCTAssertEqual(ExtensionType.firefox.rawValue, "firefox")
    }
    
    func testExtensionInitialization() {
        // Create test manifest JSON
        let manifestDict: [String: Any] = [
            "name": "Test Extension",
            "description": "A test extension",
            "version": "1.0.0"
        ]
        
        // Create content script
        let contentScript = ExtensionManager.ContentScript(
            js: ["content.js"],
            css: [],
            matches: ["*://*/*"],
            runAt: .documentEnd
        )
        
        let testExtension = ExtensionManager.Extension(
            id: "test-id",
            name: "Test Extension",
            description: "A test extension",
            version: "1.0.0",
            type: .chrome,
            enabled: true,
            manifestJson: manifestDict,
            entryPoints: ["background.js"],
            contentScripts: [contentScript],
            permissions: ["tabs"],
            optionalPermissions: []
        )
        
        XCTAssertEqual(testExtension.id, "test-id")
        XCTAssertEqual(testExtension.name, "Test Extension")
        XCTAssertEqual(testExtension.version, "1.0.0")
        XCTAssertEqual(testExtension.description, "A test extension")
        XCTAssertEqual(testExtension.type, .chrome)
        XCTAssertTrue(testExtension.enabled)
        XCTAssertEqual(testExtension.manifestJson["name"] as? String, "Test Extension")
        XCTAssertEqual(testExtension.entryPoints, ["background.js"])
        XCTAssertEqual(testExtension.contentScripts.count, 1)
        XCTAssertEqual(testExtension.permissions, ["tabs"])
    }
    
    func testDisabledExtension() {
        // Create test manifest JSON
        let manifestDict: [String: Any] = [
            "name": "Disabled Extension",
            "description": "A disabled extension",
            "version": "1.0.0"
        ]
        
        let testExtension = ExtensionManager.Extension(
            id: "disabled-ext",
            name: "Disabled Extension",
            description: "A disabled extension",
            version: "1.0.0",
            type: .firefox,
            enabled: false,
            manifestJson: manifestDict,
            entryPoints: nil,
            contentScripts: [],
            permissions: [],
            optionalPermissions: []
        )
        
        XCTAssertFalse(testExtension.enabled, "Extension should be disabled")
        XCTAssertEqual(testExtension.type, .firefox)
        XCTAssertNil(testExtension.entryPoints)
        XCTAssertTrue(testExtension.contentScripts.isEmpty)
    }
} 