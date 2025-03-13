import XCTest
@testable import NorioUI
@testable import NorioCore

final class BrowserViewTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testBrowserViewInitialization() {
        // Since BrowserView is likely a SwiftUI view, we'll test some basic functionality
        // This is more of a smoke test than a full UI test
        
        // Check that the BrowserEngine is properly initialized
        let browserEngine = BrowserEngine.shared
        XCTAssertNotNil(browserEngine, "BrowserEngine should be initialized")
        
        // If there are any public methods or properties we can test, we would do so here
        XCTAssertTrue(browserEngine.contentBlockingEnabled, "Content blocking should be enabled by default")
    }
    
    // Mock test for URL validation (assuming the app has URL validation)
    func testURLValidation() {
        // Valid URLs
        XCTAssertTrue(isValidURL("https://www.apple.com"))
        XCTAssertTrue(isValidURL("http://example.com"))
        XCTAssertTrue(isValidURL("https://subdomain.example.co.uk/path?query=value"))
        
        // Invalid URLs
        XCTAssertFalse(isValidURL("not a url"))
        XCTAssertFalse(isValidURL("http://"))
        XCTAssertFalse(isValidURL("www.example"))
    }
    
    // Helper function to simulate URL validation
    // In a real implementation, this would call the actual validation method from your app
    private func isValidURL(_ string: String) -> Bool {
        guard let url = URL(string: string) else { return false }
        return url.scheme != nil && url.host != nil
    }
}

// XCUITest extension for UI element testing
class BrowserViewUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testUIElementsExist() {
        // Test that key UI elements exist in the interface
        XCTAssertTrue(app.buttons["backButton"].exists, "Back button should exist")
        XCTAssertTrue(app.buttons["forwardButton"].exists, "Forward button should exist")
        XCTAssertTrue(app.buttons["refreshButton"].exists, "Refresh button should exist")
        XCTAssertTrue(app.textFields["addressBar"].exists, "Address bar should exist")
        XCTAssertTrue(app.buttons["settingsButton"].exists, "Settings button should exist")
        XCTAssertTrue(app.buttons["extensionsDropdownButton"].exists, "Extensions dropdown button should exist")
        XCTAssertTrue(app.buttons["newTabButton"].exists, "New tab button should exist")
    }
    
    func testAddressBarInteraction() {
        // Test entering a URL in the address bar
        let addressBar = app.textFields["addressBar"]
        XCTAssertTrue(addressBar.exists, "Address bar should exist")
        
        // Tap the address bar and enter a URL
        addressBar.tap()
        addressBar.typeText("https://www.apple.com\n")
        
        // Wait for the page to load
        let webView = app.otherElements["webViewParent"]
        XCTAssertTrue(webView.waitForExistence(timeout: 5), "Web view should exist after loading a page")
    }
    
    func testTabNavigation() {
        // Test creating a new tab
        let newTabButton = app.buttons["newTabButton"]
        XCTAssertTrue(newTabButton.exists, "New tab button should exist")
        
        // Initial tab should exist
        let initialTab = app.otherElements.matching(identifier: /tab-.*/).firstMatch
        XCTAssertTrue(initialTab.exists, "Initial tab should exist")
        
        // Click new tab button to create a second tab
        newTabButton.tap()
        
        // There should now be two tabs
        let tabCount = app.otherElements.matching(identifier: /tab-.*/).count
        XCTAssertEqual(tabCount, 2, "There should be two tabs after creating a new one")
        
        // Select the first tab
        app.otherElements.matching(identifier: /tab-.*/).element(boundBy: 0).tap()
        
        // Close the current tab
        let closeTabButton = app.buttons["closeTabButton"]
        closeTabButton.tap()
        
        // There should now be one tab
        let newTabCount = app.otherElements.matching(identifier: /tab-.*/).count
        XCTAssertEqual(newTabCount, 1, "There should be one tab after closing one")
    }
    
    func testNavigationButtons() {
        // Test back and forward navigation
        let addressBar = app.textFields["addressBar"]
        let backButton = app.buttons["backButton"]
        let forwardButton = app.buttons["forwardButton"]
        
        // Load first page
        addressBar.tap()
        addressBar.typeText("https://www.apple.com\n")
        
        // Wait for the page to load
        let webView = app.otherElements["webViewParent"]
        XCTAssertTrue(webView.waitForExistence(timeout: 5), "Web view should exist after loading a page")
        
        // Load second page
        addressBar.tap()
        addressBar.clearText()
        addressBar.typeText("https://www.google.com\n")
        
        // Wait for the second page to load
        XCTAssertTrue(webView.waitForExistence(timeout: 5), "Web view should exist after loading a second page")
        
        // Test back button
        backButton.tap()
        
        // Test forward button
        forwardButton.tap()
    }
}

// MARK: - Helper Extensions for UI Testing

extension XCUIElement {
    func clearText() {
        guard let stringValue = self.value as? String else {
            return
        }
        
        // Tap to activate the field
        self.tap()
        
        // Delete the existing text
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
    }
} 