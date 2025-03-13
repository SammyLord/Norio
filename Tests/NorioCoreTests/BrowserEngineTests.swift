import XCTest
@testable import NorioCore

final class BrowserEngineTests: XCTestCase {
    var browserEngine: BrowserEngine!
    
    override func setUp() {
        super.setUp()
        browserEngine = BrowserEngine.shared
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testBrowserEngineInitialization() {
        XCTAssertNotNil(browserEngine, "BrowserEngine should not be nil")
        XCTAssertTrue(browserEngine.contentBlockingEnabled, "Content blocking should be enabled by default")
    }
    
    func testToggleContentBlocking() {
        // Initially, it should be enabled
        XCTAssertTrue(browserEngine.contentBlockingEnabled)
        
        // Disable content blocking
        browserEngine.contentBlockingEnabled = false
        XCTAssertFalse(browserEngine.contentBlockingEnabled)
        // Also verify that ContentBlocker's isEnabled property has been updated
        XCTAssertFalse(ContentBlocker.shared.isEnabled)
        
        // Enable content blocking again
        browserEngine.contentBlockingEnabled = true
        XCTAssertTrue(browserEngine.contentBlockingEnabled)
        // Also verify that ContentBlocker's isEnabled property has been updated
        XCTAssertTrue(ContentBlocker.shared.isEnabled)
    }
    
    func testCreateWebView() {
        let webView = browserEngine.createWebView()
        XCTAssertNotNil(webView, "WebView should be created successfully")
        
        // Check configuration settings
        let configuration = webView.configuration
        
        #if os(macOS)
        // Developer extras should be enabled on macOS
        let developerExtrasEnabled = configuration.preferences.value(forKey: "developerExtrasEnabled") as? Bool
        XCTAssertTrue(developerExtrasEnabled ?? false)
        #endif
        
        // Test JavaScript settings
        XCTAssertTrue(configuration.defaultWebpagePreferences.allowsContentJavaScript, "JavaScript should be enabled by default")
        XCTAssertFalse(configuration.preferences.javaScriptCanOpenWindowsAutomatically, "JavaScript should not be able to open windows automatically")
        
        // Test file access settings
        let fileAccessEnabled = configuration.preferences.value(forKey: "allowFileAccessFromFileURLs") as? Bool
        XCTAssertTrue(fileAccessEnabled ?? false, "File access from file URLs should be enabled")
    }
} 