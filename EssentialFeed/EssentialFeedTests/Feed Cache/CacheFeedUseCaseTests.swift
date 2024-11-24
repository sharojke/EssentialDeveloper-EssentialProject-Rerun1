import EssentialFeed
import XCTest

final class CacheFeedUseCaseTests: XCTestCase {
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertTrue(store.receivedMessages.isEmpty)
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()
        store.completeDeletion(with: deletionError)
        
        try? sut.save(uniqueFeed().models)
        
        XCTAssertTrue(store.receivedMessages == [.deleteCachedFeed])
    }
    
    func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let (models, local) = uniqueFeed()
        store.completeDeletionSuccessfully()
        
        try? sut.save(models)
        
        XCTAssertTrue(store.receivedMessages == [.deleteCachedFeed, .insert(local, timestamp)])
    }
    
    func test_save_failsOnDeletionError() {
        let expectedError = anyNSError()
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWithResult: .failure(expectedError)) {
            store.completeDeletion(with: expectedError)
        }
    }
    
    func test_save_failsOnInsertionError() {
        let expectedError = anyNSError()
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWithResult: .failure(expectedError)) {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: expectedError)
        }
    }
    
    func test_save_succeedsOnSuccessfulCacheInsertion() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWithResult: .success(Void())) {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        }
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        currentDate: @escaping () -> Date = Date.init,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func expect(
        _ sut: LocalFeedLoader,
        toCompleteWithResult expectedResult: Result<Void, Error>,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        action()
        let receivedResult = Result { try sut.save(uniqueFeed().models) }
                
        switch (receivedResult, expectedResult) {
        case (.success, .success):
            break
            
        case let(.failure(receivedError as NSError), .failure(expectedError as NSError)):
            XCTAssertEqual(receivedError.code, expectedError.code, file: file, line: line)
            XCTAssertEqual(receivedError.domain, expectedError.domain, file: file, line: line)
            
        default:
            XCTFail(
                "Expected \(expectedResult), received \(receivedResult as Any) instead",
                file: file,
                line: line
            )
        }
    }
}
