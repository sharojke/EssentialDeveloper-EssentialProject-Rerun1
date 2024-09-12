import XCTest

protocol FeedStore {}

private final class FeedStoreSpy: FeedStore {
    private(set) var deleteCachedFeedCallCount = 0
}

final class LocalFeedLoader {
    private let store: FeedStore
    
    init(store: FeedStore) {
        self.store = store
    }
}

final class CacheFeedUseCaseTests: XCTestCase {
    func test_init_doesNotDeleteCacheUponCreation() {
        let store = FeedStoreSpy()
        _ = LocalFeedLoader(store: store)
        
        XCTAssertTrue(store.deleteCachedFeedCallCount == .zero)
    }
}
