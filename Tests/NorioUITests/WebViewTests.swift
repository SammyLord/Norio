import XCTest
@testable import NorioUI
@testable import NorioCore

class WebViewTests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testWebViewLoading() {
        // Enter a URL in the address bar
        let addressBar = app.textFields["addressBar"]
        XCTAssertTrue(addressBar.exists, "Address bar should exist")
        
        addressBar.tap()
        addressBar.typeText("https://www.apple.com\n")
        
        // Check that the WebView container exists
        let webViewContainer = app.otherElements["webViewParent"]
        XCTAssertTrue(webViewContainer.waitForExistence(timeout: 5), "WebView container should exist")
        
        // Check that the status bar updates with the domain
        let statusBar = app.otherElements["statusBar"]
        XCTAssertTrue(statusBar.waitForExistence(timeout: 5), "Status bar should exist")
        
        let statusText = app.staticTexts["statusUrl"]
        XCTAssertTrue(statusText.waitForExistence(timeout: 5), "Status URL text should exist")
        XCTAssertEqual(statusText.label, "www.apple.com", "Status URL should show the correct domain")
    }
    
    func testNavigationHistory() {
        // Load first page
        let addressBar = app.textFields["addressBar"]
        addressBar.tap()
        addressBar.typeText("https://www.apple.com\n")
        
        // Wait for the page to load
        let webView = app.otherElements["webViewParent"]
        XCTAssertTrue(webView.waitForExistence(timeout: 5), "WebView should exist after loading a page")
        
        // Load second page
        addressBar.tap()
        addressBar.clearText()
        addressBar.typeText("https://www.google.com\n")
        
        // Wait for the second page to load and check status
        let timeout = 5.0
        let expectation = XCTestExpectation(description: "Wait for page to load")
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout + 1.0)
        
        let statusText = app.staticTexts["statusUrl"]
        XCTAssertTrue(statusText.label.contains("google"), "Status URL should show the Google domain")
        
        // Test back button
        let backButton = app.buttons["backButton"]
        backButton.tap()
        
        // Wait for back navigation and check status
        let backExpectation = XCTestExpectation(description: "Wait for back navigation")
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            backExpectation.fulfill()
        }
        wait(for: [backExpectation], timeout: timeout + 1.0)
        
        XCTAssertTrue(statusText.label.contains("apple"), "Status URL should show the Apple domain after back navigation")
        
        // Test forward button
        let forwardButton = app.buttons["forwardButton"]
        forwardButton.tap()
        
        // Wait for forward navigation and check status
        let forwardExpectation = XCTestExpectation(description: "Wait for forward navigation")
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            forwardExpectation.fulfill()
        }
        wait(for: [forwardExpectation], timeout: timeout + 1.0)
        
        XCTAssertTrue(statusText.label.contains("google"), "Status URL should show the Google domain after forward navigation")
    }
    
    func testRefreshButton() {
        // Load a page
        let addressBar = app.textFields["addressBar"]
        addressBar.tap()
        addressBar.typeText("https://www.apple.com\n")
        
        // Wait for the page to load
        let webView = app.otherElements["webViewParent"]
        XCTAssertTrue(webView.waitForExistence(timeout: 5), "WebView should exist after loading a page")
        
        // Test the refresh button
        let refreshButton = app.buttons["refreshButton"]
        refreshButton.tap()
        
        // Verify that the page is refreshing (in a real test, you might check for specific UI indicators)
        // For now, we'll just wait a moment and assume it refreshed
        let timeout = 2.0
        let expectation = XCTestExpectation(description: "Wait for page refresh")
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout + 1.0)
    }
    
    func testMultipleTabs() {
        // Load first page in initial tab
        let addressBar = app.textFields["addressBar"]
        addressBar.tap()
        addressBar.typeText("https://www.apple.com\n")
        
        // Wait for the page to load
        let webView = app.otherElements["webViewParent"]
        XCTAssertTrue(webView.waitForExistence(timeout: 5), "WebView should exist after loading a page")
        
        // Create a new tab
        let newTabButton = app.buttons["newTabButton"]
        newTabButton.tap()
        
        // Load a different page in the new tab
        addressBar.tap()
        addressBar.clearText()
        addressBar.typeText("https://www.google.com\n")
        
        // Wait for the second page to load
        let timeout = 5.0
        let expectation = XCTestExpectation(description: "Wait for second page to load")
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout + 1.0)
        
        // Switch back to the first tab
        let tabs = app.otherElements.matching(identifier: /tab-.*/)
        XCTAssertEqual(tabs.count, 2, "There should be two tabs")
        
        tabs.element(boundBy: 0).tap()
        
        // Check that we're back on the first page
        let statusText = app.staticTexts["statusUrl"]
        
        let firstTabExpectation = XCTestExpectation(description: "Wait for first tab content")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            firstTabExpectation.fulfill()
        }
        wait(for: [firstTabExpectation], timeout: 3.0)
        
        XCTAssertTrue(statusText.label.contains("apple"), "Status URL should show the Apple domain in the first tab")
    }
} 