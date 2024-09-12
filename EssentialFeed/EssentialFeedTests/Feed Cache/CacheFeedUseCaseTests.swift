import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping

protocol FeedStore {
    func deleteCachedFeed()
}

private final class FeedStoreSpy: FeedStore {
    private(set) var deleteCachedFeedCallCount = 0
    
    func deleteCachedFeed() {
        deleteCachedFeedCallCount += 1
    }
}

final class LocalFeedLoader {
    private let store: FeedStore
    
    init(store: FeedStore) {
        self.store = store
    }
    
    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed()
    }
}

final class CacheFeedUseCaseTests: XCTestCase {
    func test_init_doesNotDeleteCacheUponCreation() {
        let store = FeedStoreSpy()
        _ = LocalFeedLoader(store: store)
        
        XCTAssertTrue(store.deleteCachedFeedCallCount == .zero)
    }
    
    func test_save_requestsCacheDeletion() {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store)
        let items = [uniqueItem(), uniqueItem()]
        
        sut.save(items)
        
        XCTAssertTrue(store.deleteCachedFeedCallCount == 1)
    }
    
    // MARK: Helpers
    
    private func uniqueItem() -> FeedItem {
        return FeedItem(
            id: UUID(),
            description: "a description",
            location: "a location",
            imageURL: anyURL()
        )
    }
    
    private func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }
}

// swiftlint:enable force_unwrapping
