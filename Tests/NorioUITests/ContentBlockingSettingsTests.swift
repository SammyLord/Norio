import XCTest
@testable import NorioUI
@testable import NorioCore

class ContentBlockingSettingsTests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testContentBlockingSettingsNavigation() {
        // Open settings
        app.buttons["settingsButton"].tap()
        
        // Navigate to content blocking settings
        let contentBlockingLink = app.buttons["contentBlockingSettingsLink"]
        XCTAssertTrue(contentBlockingLink.waitForExistence(timeout: 2), "Content blocking settings link should exist")
        contentBlockingLink.tap()
        
        // Verify we're on the content blocking screen
        let contentBlockingScreen = app.otherElements["contentBlockingScreen"]
        XCTAssertTrue(contentBlockingScreen.waitForExistence(timeout: 2), "Content blocking screen should be displayed")
    }
    
    func testAddCustomBlockList() {
        // Navigate to content blocking settings
        app.buttons["settingsButton"].tap()
        app.buttons["contentBlockingSettingsLink"].tap()
        
        // Tap the add block list button
        let addButton = app.buttons["addBlockListButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 2), "Add block list button should exist")
        addButton.tap()
        
        // Verify the add block list screen is displayed
        let addBlockListScreen = app.otherElements["addBlockListScreen"]
        XCTAssertTrue(addBlockListScreen.waitForExistence(timeout: 2), "Add block list screen should be displayed")
        
        // Fill in the form
        let nameField = app.textFields["blockListNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2), "Name field should exist")
        nameField.tap()
        nameField.typeText("Test Block List")
        
        let urlField = app.textFields["blockListURLField"]
        XCTAssertTrue(urlField.waitForExistence(timeout: 2), "URL field should exist")
        urlField.tap()
        urlField.typeText("https://example.com/blocklist.txt")
        
        let categoryPicker = app.pickers["blockListCategoryPicker"]
        if categoryPicker.exists {
            categoryPicker.tap()
            
            // Select "Trackers" category
            app.pickerWheels.element.adjust(toPickerWheelValue: "Trackers")
            
            // Tap done if on iOS
            app.buttons["Done"].tap()
        }
        
        // Tap the add button
        let addConfirmButton = app.buttons["addBlockListConfirmButton"]
        XCTAssertTrue(addConfirmButton.waitForExistence(timeout: 2), "Add confirm button should exist")
        addConfirmButton.tap()
    }
    
    func testUpdateBlockLists() {
        // Navigate to content blocking settings
        app.buttons["settingsButton"].tap()
        app.buttons["contentBlockingSettingsLink"].tap()
        
        // Tap the update block lists button
        let updateButton = app.buttons["updateBlockListsButton"]
        XCTAssertTrue(updateButton.waitForExistence(timeout: 2), "Update block lists button should exist")
        updateButton.tap()
        
        // Check for updating indicator
        let updatingText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Updating")).firstMatch
        if updatingText.exists {
            // Wait for the update to complete (this could take some time in a real app)
            let timeout = 5.0
            let expectation = XCTestExpectation(description: "Wait for update to complete")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: timeout + 1.0)
        }
    }
    
    func testResetToDefaults() {
        // Navigate to content blocking settings
        app.buttons["settingsButton"].tap()
        app.buttons["contentBlockingSettingsLink"].tap()
        
        // Tap the reset to defaults button
        let resetButton = app.buttons["resetToDefaultsButton"]
        XCTAssertTrue(resetButton.waitForExistence(timeout: 2), "Reset to defaults button should exist")
        resetButton.tap()
        
        // Check for default block lists (this is a basic check - in a real test you might verify specific lists exist)
        let blockLists = app.otherElements.matching(identifier: "blockList-.*")
        XCTAssertTrue(blockLists.count > 0, "Default block lists should be displayed after reset")
    }
} 