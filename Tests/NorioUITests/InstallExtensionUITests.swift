import XCTest
@testable import NorioUI
@testable import NorioCore
@testable import NorioExtensions

class InstallExtensionUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testInstallFromURLFlow() {
        // Open the extensions management view
        app.buttons["extensionsDropdownButton"].tap()
        
        let manageExtensionsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Manage Extensions")).firstMatch
        if manageExtensionsButton.exists {
            manageExtensionsButton.tap()
            
            // Tap the "Install from URL" button
            let installFromURLButton = app.buttons["installFromURLButton"]
            XCTAssertTrue(installFromURLButton.waitForExistence(timeout: 2), "Install from URL button should exist")
            installFromURLButton.tap()
            
            // Fill in the extension details
            let typeSegmentedControl = app.segmentedControls.firstMatch
            XCTAssertTrue(typeSegmentedControl.waitForExistence(timeout: 2), "Extension type segmented control should exist")
            
            // Enter a URL
            let urlField = app.textFields.firstMatch
            XCTAssertTrue(urlField.waitForExistence(timeout: 2), "URL field should exist")
            urlField.tap()
            urlField.typeText("https://example.com/extension.crx")
            
            // Try to install
            let installButton = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Install Extension")).firstMatch
            XCTAssertTrue(installButton.waitForExistence(timeout: 2), "Install button should exist")
            installButton.tap()
        }
    }
    
    func testBrowseExtensionStores() {
        // Open the extensions management view
        app.buttons["extensionsDropdownButton"].tap()
        
        let manageExtensionsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Manage Extensions")).firstMatch
        if manageExtensionsButton.exists {
            manageExtensionsButton.tap()
            
            // Tap the "Browse Extension Stores" button
            let browseStoresButton = app.buttons["browseExtensionStoresButton"]
            XCTAssertTrue(browseStoresButton.waitForExistence(timeout: 2), "Browse Extension Stores button should exist")
            browseStoresButton.tap()
            
            // Verify the store picker exists
            let storePicker = app.segmentedControls.firstMatch
            XCTAssertTrue(storePicker.waitForExistence(timeout: 2), "Store type segmented control should exist")
            
            // Test switching between stores
            let chromeStore = storePicker.buttons.element(boundBy: 0)
            let firefoxStore = storePicker.buttons.element(boundBy: 1)
            
            XCTAssertTrue(chromeStore.exists, "Chrome Web Store button should exist")
            XCTAssertTrue(firefoxStore.exists, "Firefox Add-ons button should exist")
            
            // Test search field
            let searchField = app.textFields.firstMatch
            XCTAssertTrue(searchField.waitForExistence(timeout: 2), "Search field should exist")
            searchField.tap()
            searchField.typeText("uBlock Origin")
            
            // Tap search button
            let searchButton = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Search")).firstMatch
            XCTAssertTrue(searchButton.waitForExistence(timeout: 2), "Search button should exist")
            searchButton.tap()
            
            // Close the web stores sheet
            let doneButton = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Done")).firstMatch
            XCTAssertTrue(doneButton.waitForExistence(timeout: 2), "Done button should exist")
            doneButton.tap()
        }
    }
} 