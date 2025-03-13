import XCTest
@testable import NorioCore

final class BlockListTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testBlockListCategoryEnum() {
        // Test enum cases
        XCTAssertEqual(BlockListCategory.ads.rawValue, "ads")
        XCTAssertEqual(BlockListCategory.trackers.rawValue, "trackers")
        XCTAssertEqual(BlockListCategory.both.rawValue, "both")
    }
    
    func testBlockListCreation() {
        let uuid = UUID()
        let url = URL(string: "https://example.com/list.txt")!
        let now = Date()
        
        let blockList = BlockList(
            id: uuid,
            name: "Test Block List",
            url: url,
            isEnabled: true,
            category: .ads,
            lastUpdated: now
        )
        
        // Verify all properties
        XCTAssertEqual(blockList.id, uuid)
        XCTAssertEqual(blockList.name, "Test Block List")
        XCTAssertEqual(blockList.url, url)
        XCTAssertTrue(blockList.isEnabled)
        XCTAssertEqual(blockList.category, .ads)
        XCTAssertEqual(blockList.lastUpdated, now)
        XCTAssertEqual(blockList.ruleCount, 0)  // Default value
    }
    
    func testBlockListEquality() {
        let id1 = UUID()
        let id2 = UUID()
        let url = URL(string: "https://example.com/list.txt")!
        
        let list1 = BlockList(id: id1, name: "List 1", url: url, isEnabled: true, category: .ads)
        let list2 = BlockList(id: id1, name: "List 1", url: url, isEnabled: true, category: .ads)
        let list3 = BlockList(id: id2, name: "List 2", url: url, isEnabled: false, category: .trackers)
        
        // Two lists with the same ID should be equal
        XCTAssertEqual(list1, list2)
        
        // Two lists with different IDs should not be equal
        XCTAssertNotEqual(list1, list3)
    }
    
    func testBlockListDisabled() {
        let url = URL(string: "https://example.com/list.txt")!
        let blockList = BlockList(
            name: "Disabled List",
            url: url,
            isEnabled: false,
            category: .trackers
        )
        
        XCTAssertFalse(blockList.isEnabled, "Block list should be disabled")
        XCTAssertEqual(blockList.category, .trackers)
        XCTAssertNil(blockList.lastUpdated, "Last updated should be nil for a newly created block list")
    }
} 
