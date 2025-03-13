import XCTest
@testable import NorioUI
@testable import NorioCore
@testable import NorioExtensions

class ExtensionsUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testExtensionsManagementFlow() {
        // Navigate to the extensions menu
        let extensionsButton = app.buttons["extensionsDropdownButton"]
        XCTAssertTrue(extensionsButton.waitForExistence(timeout: 2), "Extensions dropdown button should exist")
        extensionsButton.tap()
        
        // Tap on "Manage Extensions"
        let manageExtensionsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Manage Extensions")).firstMatch
        XCTAssertTrue(manageExtensionsButton.waitForExistence(timeout: 2), "Manage Extensions button should exist")
        manageExtensionsButton.tap()
        
        // Verify the extensions screen is displayed
        let extensionsScreen = app.otherElements["extensionsScreen"]
        XCTAssertTrue(extensionsScreen.waitForExistence(timeout: 2), "Extensions screen should be displayed")
        
        // Test that the installed extensions list exists (might be empty on first run)
        let installedExtensionsSection = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Installed Extensions")).firstMatch
        XCTAssertTrue(installedExtensionsSection.exists, "Installed Extensions section should exist")
        
        // Test the browse extension stores button
        let browseStoresButton = app.buttons["browseExtensionStoresButton"]
        XCTAssertTrue(browseStoresButton.exists, "Browse Extension Stores button should exist")
        
        // Test the install from URL button
        let installFromURLButton = app.buttons["installFromURLButton"]
        XCTAssertTrue(installFromURLButton.exists, "Install from URL button should exist")
        
        // Test the done button
        let doneButton = app.buttons["doneExtensionsButton"]
        XCTAssertTrue(doneButton.exists, "Done button should exist")
        doneButton.tap()
    }
    
    func testToggleExtension() {
        // This test assumes there's at least one extension installed
        // First we'll install a test extension if needed
        
        // Navigate to extensions screen
        app.buttons["extensionsDropdownButton"].tap()
        let manageExtensionsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Manage Extensions")).firstMatch
        manageExtensionsButton.tap()
        
        // Check if there are any extensions
        let noExtensionsMessage = app.staticTexts["noExtensionsMessage"]
        
        if noExtensionsMessage.exists {
            // Install a test extension using the Chrome store
            app.buttons["browseExtensionStoresButton"].tap()
            
            // Make sure we're on Chrome store
            let storePicker = app.segmentedControls["storeTypePicker"]
            XCTAssertTrue(storePicker.waitForExistence(timeout: 2), "Store type picker should exist")
            
            let chromeButton = storePicker.buttons.element(boundBy: 0)
            chromeButton.tap()
            
            // Search for uBlock Origin as a test
            let searchField = app.textFields["extensionSearchField"]
            XCTAssertTrue(searchField.waitForExistence(timeout: 2), "Search field should exist")
            searchField.tap()
            searchField.typeText("uBlock Origin")
            
            app.buttons["extensionSearchButton"].tap()
            
            // Wait for search results
            let webView = app.otherElements["storeWebView"]
            XCTAssertTrue(webView.waitForExistence(timeout: 5), "Web view should exist")
            
            // Go back to extensions screen
            app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Done")).firstMatch.tap()
        }
        
        // Find an extension toggle (if one exists)
        let extensionToggle = app.switches["extensionToggle"].firstMatch
        
        if extensionToggle.exists {
            // Get the current value
            let initialValue = extensionToggle.value as? String
            
            // Toggle the extension
            extensionToggle.tap()
            
            // Verify the toggle changed state
            let newValue = extensionToggle.value as? String
            XCTAssertNotEqual(initialValue, newValue, "Extension toggle should change state")
            
            // Toggle back to original state
            extensionToggle.tap()
            
            // Verify it went back to original state
            let finalValue = extensionToggle.value as? String
            XCTAssertEqual(initialValue, finalValue, "Extension toggle should return to original state")
        }
        
        // Go back to main screen
        app.buttons["doneExtensionsButton"].tap()
    }
    
    func testExtensionInstallFromURL() {
        // Navigate to extensions screen
        app.buttons["extensionsDropdownButton"].tap()
        let manageExtensionsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Manage Extensions")).firstMatch
        manageExtensionsButton.tap()
        
        // Tap the "Install From URL" button
        let installFromURLButton = app.buttons["installFromURLButton"]
        XCTAssertTrue(installFromURLButton.waitForExistence(timeout: 2), "Install from URL button should exist")
        installFromURLButton.tap()
        
        // Verify the install sheet is displayed
        let installSheet = app.navigationBars.matching(NSPredicate(format: "identifier CONTAINS %@", "Install Extension")).firstMatch
        XCTAssertTrue(installSheet.waitForExistence(timeout: 2), "Install extension sheet should be displayed")
        
        // Test the extension type picker
        let typePicker = app.segmentedControls.firstMatch
        XCTAssertTrue(typePicker.waitForExistence(timeout: 2), "Extension type picker should exist")
        
        // Default should be Chrome
        let chromeButton = typePicker.buttons.element(boundBy: 0)
        XCTAssertTrue(chromeButton.isSelected, "Chrome should be selected by default")
        
        // Switch to Firefox
        let firefoxButton = typePicker.buttons.element(boundBy: 1)
        firefoxButton.tap()
        
        // Enter a test URL
        let urlField = app.textFields.firstMatch
        XCTAssertTrue(urlField.waitForExistence(timeout: 2), "URL field should exist")
        urlField.tap()
        urlField.typeText("https://example.com/test-addon.xpi")
        
        // Install button should be enabled
        let installButton = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Install Extension")).firstMatch
        XCTAssertTrue(installButton.isEnabled, "Install button should be enabled after entering URL")
        
        // Cancel instead of actually installing
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Cancel")).firstMatch.tap()
        
        // Go back to main screen
        app.buttons["doneExtensionsButton"].tap()
    }
    
    func testExtensionContextMenu() {
        // This test assumes there's at least one extension installed
        // Navigate to extensions screen
        app.buttons["extensionsDropdownButton"].tap()
        let manageExtensionsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Manage Extensions")).firstMatch
        manageExtensionsButton.tap()
        
        // Check if there are any extensions
        let noExtensionsMessage = app.staticTexts["noExtensionsMessage"]
        
        if !noExtensionsMessage.exists {
            // Find an extension item
            let extensionItem = app.otherElements.matching(identifier: /extension-.*/).firstMatch
            
            if extensionItem.exists {
                // Long press to open context menu
                extensionItem.press(forDuration: 1.0)
                
                // Check for the remove option
                let removeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Remove Extension")).firstMatch
                
                // Wait for context menu to appear
                let timeout = 2.0
                let contextMenuAppeared = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == YES"), object: removeButton)], timeout: timeout)
                
                if contextMenuAppeared == .completed {
                    // Do nothing (don't actually remove the extension)
                    // Tap elsewhere to dismiss the context menu
                    app.tap()
                }
            }
        }
        
        // Go back to main screen
        app.buttons["doneExtensionsButton"].tap()
    }
} 