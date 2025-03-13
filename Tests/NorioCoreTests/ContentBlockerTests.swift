import XCTest
@testable import NorioCore

final class ContentBlockerTests: XCTestCase {
    var contentBlocker: ContentBlocker!
    
    override func setUp() {
        super.setUp()
        contentBlocker = ContentBlocker.shared
        // Reset the content blocker state
        contentBlocker.isEnabled = true
    }
    
    override func tearDown() {
        // Clean up after each test
        super.tearDown()
    }
    
    func testContentBlockerInitialization() {
        XCTAssertNotNil(contentBlocker, "ContentBlocker should not be nil")
        XCTAssertTrue(contentBlocker.isEnabled, "ContentBlocker should be enabled by default")
    }
    
    func testToggleContentBlocker() {
        // Initially, it should be enabled
        XCTAssertTrue(contentBlocker.isEnabled)
        
        // Disable it
        contentBlocker.isEnabled = false
        XCTAssertFalse(contentBlocker.isEnabled)
        
        // Enable it again
        contentBlocker.isEnabled = true
        XCTAssertTrue(contentBlocker.isEnabled)
    }
    
    func testBlockListCategory() {
        // Test BlockListCategory enum
        XCTAssertEqual(BlockListCategory.ads.rawValue, "ads")
        XCTAssertEqual(BlockListCategory.trackers.rawValue, "trackers")
        XCTAssertEqual(BlockListCategory.both.rawValue, "both")
    }
    
    func testBlockListEquality() {
        let url = URL(string: "https://example.com/list.txt")!
        let list1 = BlockList(id: UUID(), name: "Test List", url: url, isEnabled: true, category: .ads)
        let list2 = BlockList(id: list1.id, name: "Test List", url: url, isEnabled: true, category: .ads)
        let list3 = BlockList(id: UUID(), name: "Different List", url: url, isEnabled: true, category: .ads)
        
        XCTAssertEqual(list1, list2)
        XCTAssertNotEqual(list1, list3)
    }
} 