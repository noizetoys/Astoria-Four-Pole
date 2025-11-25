import XCTest
import SwiftUI
@testable import YourApp  // Replace with your app name

final class TagSystemTests: XCTestCase {
    
    var viewModel: TagSystemViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = TagSystemViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Tag Management Tests
    
    func testAddTag() {
        let initialCount = viewModel.availableTags.count
        let newTag = Tag(name: "Test Tag", color: .red, shape: .capsule)
        
        viewModel.addTag(newTag)
        
        XCTAssertEqual(viewModel.availableTags.count, initialCount + 1)
        XCTAssertTrue(viewModel.availableTags.contains(where: { $0.id == newTag.id }))
    }
    
    func testUpdateTag() {
        // Given: A tag is added
        let originalTag = Tag(name: "Original", color: .blue, shape: .capsule)
        viewModel.addTag(originalTag)
        
        // And: An item uses this tag
        var item = TaggedItem(title: "Test", description: "Test", tags: [originalTag])
        viewModel.items.append(item)
        
        // When: The tag is updated
        var updatedTag = originalTag
        updatedTag.name = "Updated"
        updatedTag.color = .red
        viewModel.updateTag(updatedTag)
        
        // Then: The tag is updated in the available tags
        guard let foundTag = viewModel.availableTags.first(where: { $0.id == originalTag.id }) else {
            XCTFail("Tag not found")
            return
        }
        XCTAssertEqual(foundTag.name, "Updated")
        XCTAssertEqual(foundTag.color, .red)
        
        // And: The tag is updated in all items
        guard let updatedItem = viewModel.items.first(where: { $0.id == item.id }) else {
            XCTFail("Item not found")
            return
        }
        XCTAssertTrue(updatedItem.tags.contains(where: { $0.name == "Updated" }))
        XCTAssertFalse(updatedItem.tags.contains(where: { $0.name == "Original" }))
    }
    
    func testDeleteTag() {
        // Given: A tag exists
        let tag = Tag(name: "To Delete", color: .red, shape: .capsule)
        viewModel.addTag(tag)
        
        // And: An item uses this tag
        var item = TaggedItem(title: "Test", description: "Test", tags: [tag])
        viewModel.items.append(item)
        
        let initialTagCount = viewModel.availableTags.count
        
        // When: The tag is deleted
        viewModel.deleteTag(tag)
        
        // Then: The tag is removed from available tags
        XCTAssertEqual(viewModel.availableTags.count, initialTagCount - 1)
        XCTAssertFalse(viewModel.availableTags.contains(where: { $0.id == tag.id }))
        
        // And: The tag is removed from all items
        guard let updatedItem = viewModel.items.first(where: { $0.id == item.id }) else {
            XCTFail("Item not found")
            return
        }
        XCTAssertFalse(updatedItem.tags.contains(tag))
    }
    
    func testDeleteTagFromSearchTags() {
        // Given: A tag is in the search filters
        let tag = Tag(name: "Search Tag", color: .blue, shape: .capsule)
        viewModel.addTag(tag)
        viewModel.searchTags.insert(tag)
        
        // When: The tag is deleted
        viewModel.deleteTag(tag)
        
        // Then: The tag is removed from search filters
        XCTAssertFalse(viewModel.searchTags.contains(tag))
    }
    
    // MARK: - Item Management Tests
    
    func testUpdateItemTags() {
        // Given: An item exists
        let item = TaggedItem(title: "Test", description: "Test", tags: [])
        viewModel.items.append(item)
        
        // When: Tags are added to the item
        let tag1 = viewModel.availableTags[0]
        let tag2 = viewModel.availableTags[1]
        viewModel.updateItemTags(item, tags: [tag1, tag2])
        
        // Then: The item has the new tags
        guard let updatedItem = viewModel.items.first(where: { $0.id == item.id }) else {
            XCTFail("Item not found")
            return
        }
        XCTAssertEqual(updatedItem.tags.count, 2)
        XCTAssertTrue(updatedItem.tags.contains(tag1))
        XCTAssertTrue(updatedItem.tags.contains(tag2))
    }
    
    // MARK: - Search and Filter Tests
    
    func testFilterByText() {
        // Given: Items with different titles
        let item1 = TaggedItem(title: "SwiftUI Tutorial", description: "Learn SwiftUI", tags: [])
        let item2 = TaggedItem(title: "UIKit Guide", description: "UIKit basics", tags: [])
        viewModel.items = [item1, item2]
        
        // When: Searching for "SwiftUI"
        viewModel.searchText = "SwiftUI"
        
        // Then: Only matching items are returned
        let filtered = viewModel.filteredItems
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.title, "SwiftUI Tutorial")
    }
    
    func testFilterByDescription() {
        // Given: Items with different descriptions
        let item1 = TaggedItem(title: "Tutorial", description: "Learn SwiftUI", tags: [])
        let item2 = TaggedItem(title: "Guide", description: "UIKit basics", tags: [])
        viewModel.items = [item1, item2]
        
        // When: Searching for text in description
        viewModel.searchText = "UIKit"
        
        // Then: Matching item is found
        let filtered = viewModel.filteredItems
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.title, "Guide")
    }
    
    func testFilterBySingleTag() {
        // Given: Items with different tags
        let tag1 = viewModel.availableTags[0]
        let tag2 = viewModel.availableTags[1]
        
        let item1 = TaggedItem(title: "Item 1", description: "", tags: [tag1])
        let item2 = TaggedItem(title: "Item 2", description: "", tags: [tag2])
        let item3 = TaggedItem(title: "Item 3", description: "", tags: [tag1, tag2])
        
        viewModel.items = [item1, item2, item3]
        
        // When: Filtering by one tag
        viewModel.searchTags = [tag1]
        
        // Then: Items with that tag are returned
        let filtered = viewModel.filteredItems
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.contains(where: { $0.id == item1.id }))
        XCTAssertTrue(filtered.contains(where: { $0.id == item3.id }))
    }
    
    func testFilterByMultipleTags() {
        // Given: Items with different tag combinations
        let tag1 = viewModel.availableTags[0]
        let tag2 = viewModel.availableTags[1]
        let tag3 = viewModel.availableTags[2]
        
        let item1 = TaggedItem(title: "Item 1", description: "", tags: [tag1, tag2])
        let item2 = TaggedItem(title: "Item 2", description: "", tags: [tag1, tag3])
        let item3 = TaggedItem(title: "Item 3", description: "", tags: [tag1, tag2, tag3])
        
        viewModel.items = [item1, item2, item3]
        
        // When: Filtering by multiple tags (AND logic)
        viewModel.searchTags = [tag1, tag2]
        
        // Then: Only items with ALL selected tags are returned
        let filtered = viewModel.filteredItems
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.contains(where: { $0.id == item1.id }))
        XCTAssertTrue(filtered.contains(where: { $0.id == item3.id }))
    }
    
    func testCombinedTextAndTagFilter() {
        // Given: Items with tags and text
        let tag1 = viewModel.availableTags[0]
        
        let item1 = TaggedItem(title: "SwiftUI Tutorial", description: "", tags: [tag1])
        let item2 = TaggedItem(title: "UIKit Tutorial", description: "", tags: [tag1])
        let item3 = TaggedItem(title: "SwiftUI Guide", description: "", tags: [])
        
        viewModel.items = [item1, item2, item3]
        
        // When: Filtering by both text and tag
        viewModel.searchText = "SwiftUI"
        viewModel.searchTags = [tag1]
        
        // Then: Only items matching both conditions are returned
        let filtered = viewModel.filteredItems
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.title, "SwiftUI Tutorial")
    }
    
    func testEmptyFiltersReturnsAllItems() {
        // Given: Multiple items
        let item1 = TaggedItem(title: "Item 1", description: "", tags: [])
        let item2 = TaggedItem(title: "Item 2", description: "", tags: [])
        viewModel.items = [item1, item2]
        
        // When: No filters are applied
        viewModel.searchText = ""
        viewModel.searchTags = []
        
        // Then: All items are returned
        let filtered = viewModel.filteredItems
        XCTAssertEqual(filtered.count, 2)
    }
    
    func testCaseInsensitiveSearch() {
        // Given: An item with mixed case title
        let item = TaggedItem(title: "SwiftUI Tutorial", description: "", tags: [])
        viewModel.items = [item]
        
        // When: Searching with different case
        viewModel.searchText = "swiftui"
        
        // Then: Item is found
        let filtered = viewModel.filteredItems
        XCTAssertEqual(filtered.count, 1)
    }
}

// MARK: - Tag Model Tests

final class TagTests: XCTestCase {
    
    func testTagEquality() {
        let tag1 = Tag(name: "Test", color: .blue, shape: .capsule)
        let tag2 = Tag(name: "Test", color: .blue, shape: .capsule)
        
        // Tags with different IDs should not be equal
        XCTAssertNotEqual(tag1, tag2)
    }
    
    func testTagHashability() {
        let tag = Tag(name: "Test", color: .blue, shape: .capsule)
        var set: Set<Tag> = []
        
        set.insert(tag)
        
        XCTAssertTrue(set.contains(tag))
        XCTAssertEqual(set.count, 1)
    }
    
    func testTagCodable() throws {
        // Given: A tag
        let tag = Tag(name: "Test", color: .blue, shape: .capsule)
        
        // When: Encoding to JSON
        let encoder = JSONEncoder()
        let data = try encoder.encode(tag)
        
        // Then: Can decode back to tag
        let decoder = JSONDecoder()
        let decodedTag = try decoder.decode(Tag.self, from: data)
        
        XCTAssertEqual(decodedTag.id, tag.id)
        XCTAssertEqual(decodedTag.name, tag.name)
        XCTAssertEqual(decodedTag.shape, tag.shape)
    }
    
    func testTagShapeAllCases() {
        XCTAssertEqual(TagShape.allCases.count, 4)
        XCTAssertTrue(TagShape.allCases.contains(.capsule))
        XCTAssertTrue(TagShape.allCases.contains(.roundedRectangle))
        XCTAssertTrue(TagShape.allCases.contains(.circle))
        XCTAssertTrue(TagShape.allCases.contains(.diamond))
    }
}

// MARK: - Integration Tests

final class TagSystemIntegrationTests: XCTestCase {
    
    func testCompleteTagWorkflow() {
        // This test simulates a complete user workflow
        
        let viewModel = TagSystemViewModel()
        
        // 1. User creates a new tag
        let newTag = Tag(name: "Important", color: .red, shape: .diamond)
        viewModel.addTag(newTag)
        XCTAssertTrue(viewModel.availableTags.contains(where: { $0.id == newTag.id }))
        
        // 2. User creates an item and adds the tag
        let item = TaggedItem(title: "New Project", description: "Important project", tags: [])
        viewModel.items.append(item)
        viewModel.updateItemTags(item, tags: [newTag])
        
        // 3. User searches for items with the tag
        viewModel.searchTags = [newTag]
        let filtered = viewModel.filteredItems
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.title, "New Project")
        
        // 4. User updates the tag name
        var updatedTag = newTag
        updatedTag.name = "Critical"
        viewModel.updateTag(updatedTag)
        
        // 5. Verify the tag is updated everywhere
        XCTAssertTrue(viewModel.availableTags.contains(where: { $0.name == "Critical" }))
        XCTAssertFalse(viewModel.availableTags.contains(where: { $0.name == "Important" }))
        
        // 6. User deletes the tag
        viewModel.deleteTag(updatedTag)
        
        // 7. Verify complete cleanup
        XCTAssertFalse(viewModel.availableTags.contains(where: { $0.id == newTag.id }))
        XCTAssertTrue(viewModel.items.first?.tags.isEmpty ?? false)
        XCTAssertFalse(viewModel.searchTags.contains(newTag))
    }
}
