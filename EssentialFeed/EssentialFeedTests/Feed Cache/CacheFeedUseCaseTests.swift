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
        let (_, store) = makeSUT()
        
        XCTAssertTrue(store.deleteCachedFeedCallCount == .zero)
    }
    
    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        
        sut.save(items)
        
        XCTAssertTrue(store.deleteCachedFeedCallCount == 1)
    }
    
    // MARK: Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
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
