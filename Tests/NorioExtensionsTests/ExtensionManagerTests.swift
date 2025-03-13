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
        let manifestPath = URL(fileURLWithPath: "/tmp/manifest.json")
        let iconPath = URL(fileURLWithPath: "/tmp/icon.png")
        let storeURL = URL(string: "https://chrome.google.com/webstore/detail/test-extension")
        
        let extension = ExtensionManager.Extension(
            id: "test-id",
            name: "Test Extension",
            version: "1.0.0",
            description: "A test extension",
            type: .chrome,
            enabled: true,
            manifestPath: manifestPath,
            iconPath: iconPath,
            storeURL: storeURL
        )
        
        XCTAssertEqual(extension.id, "test-id")
        XCTAssertEqual(extension.name, "Test Extension")
        XCTAssertEqual(extension.version, "1.0.0")
        XCTAssertEqual(extension.description, "A test extension")
        XCTAssertEqual(extension.type, .chrome)
        XCTAssertTrue(extension.enabled)
        XCTAssertEqual(extension.manifestPath, manifestPath)
        XCTAssertEqual(extension.iconPath, iconPath)
        XCTAssertEqual(extension.storeURL, storeURL)
    }
    
    func testDisabledExtension() {
        let manifestPath = URL(fileURLWithPath: "/tmp/manifest.json")
        
        let extension = ExtensionManager.Extension(
            id: "disabled-ext",
            name: "Disabled Extension",
            version: "1.0.0",
            description: "A disabled extension",
            type: .firefox,
            enabled: false,
            manifestPath: manifestPath
        )
        
        XCTAssertFalse(extension.enabled, "Extension should be disabled")
        XCTAssertNil(extension.iconPath, "Icon path should be nil")
        XCTAssertNil(extension.storeURL, "Store URL should be nil")
    }
} 