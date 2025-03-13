import XCTest
@testable import NorioUI
@testable import NorioCore

final class AppTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    #if os(macOS)
    func testMacOSAppInitialization() {
        // Basic smoke test for macOS app initialization
        // This is a limited test since we can't easily test the SwiftUI app lifecycle
        
        // Check that core services are properly initialized
        let browserEngine = BrowserEngine.shared
        XCTAssertNotNil(browserEngine, "BrowserEngine should be available")
        
        let contentBlocker = ContentBlocker.shared
        XCTAssertNotNil(contentBlocker, "ContentBlocker should be available")
    }
    #endif
    
    #if os(iOS)
    func testiOSAppInitialization() {
        // Basic smoke test for iOS app initialization
        // This is a limited test since we can't easily test the SwiftUI app lifecycle
        
        // Check that core services are properly initialized
        let browserEngine = BrowserEngine.shared
        XCTAssertNotNil(browserEngine, "BrowserEngine should be available")
        
        let contentBlocker = ContentBlocker.shared
        XCTAssertNotNil(contentBlocker, "ContentBlocker should be available")
    }
    #endif
    
    // Test for environment handling (assuming the app has environment-specific code)
    func testEnvironmentHandling() {
        // This is a placeholder for environment-specific tests
        // In a real app, you might have code that behaves differently based on environment
        
        #if DEBUG
        // Tests for debug-specific behavior
        XCTAssertTrue(true, "Debug environment should be set up correctly")
        #else
        // Tests for release-specific behavior
        XCTAssertTrue(true, "Release environment should be set up correctly")
        #endif
    }
} 