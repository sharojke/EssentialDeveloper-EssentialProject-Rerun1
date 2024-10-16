import XCTest

private final class LocalFeedImageDataLoader {
    private let store: LocalFeedImageDataLoaderTests.FeedStoreSpy
    
    init(store: LocalFeedImageDataLoaderTests.FeedStoreSpy) {
        self.store = store
    }
}

final class LocalFeedImageDataLoaderTests: XCTestCase {
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertTrue(store.receivedMessages.isEmpty)
    }
    
    // MARK: Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: LocalFeedImageDataLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedImageDataLoader(store: store)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
}

private extension LocalFeedImageDataLoaderTests {
    final class FeedStoreSpy {
        let receivedMessages = [Any]()
    }
}
