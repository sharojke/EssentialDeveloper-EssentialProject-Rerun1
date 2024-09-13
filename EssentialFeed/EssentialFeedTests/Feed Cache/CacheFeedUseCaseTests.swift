import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping

private final class FeedStoreSpy: FeedStore {
    enum Message: Equatable {
        case deleteCachedFeed
        case insert([LocalFeedItem], Date)
    }
    
    private(set) var receivedMessages = [Message]()
    private var deletionCompletions = [(DeleteResult) -> Void]()
    private var insertionCompletions = [(InsertResult) -> Void]()
    
    func deleteCachedFeed(completion: @escaping (DeleteResult) -> Void) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCachedFeed)
    }
    
    func insert(_ items: [LocalFeedItem], timestamp: Date, completion: @escaping (InsertResult) -> Void) {
        insertionCompletions.append(completion)
        receivedMessages.append(.insert(items, timestamp))
    }
    
    func completeDeletion(with error: Error, at index: Int = .zero) {
        deletionCompletions[index](.failure(error))
    }
    
    func completeDeletionSuccessfully(at index: Int = .zero) {
        deletionCompletions[index](.success(Void()))
    }
    
    func completeInsertion(with error: Error, at index: Int = .zero) {
        insertionCompletions[index](.failure(error))
    }
    
    func completeInsertionSuccessfully(at index: Int = .zero) {
        insertionCompletions[index](.success(Void()))
    }
}

final class CacheFeedUseCaseTests: XCTestCase {
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertTrue(store.receivedMessages.isEmpty)
    }
    
    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        
        sut.save(items) { _ in }
        
        XCTAssertTrue(store.receivedMessages == [.deleteCachedFeed])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        let deletionError = anyNSError()
        
        sut.save(items) { _ in }
        store.completeDeletion(with: deletionError)
        
        XCTAssertTrue(store.receivedMessages == [.deleteCachedFeed])
    }
    
    func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let items = [uniqueItem(), uniqueItem()]
        let localItems = items.map { item in
            LocalFeedItem(
                id: item.id,
                description: item.description,
                location: item.location,
                imageURL: item.imageURL
            )
        }
        
        sut.save(items) { _ in }
        store.completeDeletionSuccessfully()
        
        XCTAssertTrue(store.receivedMessages == [.deleteCachedFeed, .insert(localItems, timestamp)])
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
    
    func test_save_doesNotDeliverDeletionErrorAfterSUTHasBeenDeallocated() {
        var (sut, store): (LocalFeedLoader?, FeedStoreSpy) = makeSUT()
        
        var receivedResults = [LocalFeedLoader.SaveResult]()
        sut?.save([uniqueItem()]) { receivedResults.append($0) }
        
        sut = nil
        store.completeDeletion(with: anyNSError())
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    func test_save_doesNotDeliverInsertionErrorAfterSUTHasBeenDeallocated() {
        var (sut, store): (LocalFeedLoader?, FeedStoreSpy) = makeSUT()
        
        var receivedResults = [LocalFeedLoader.SaveResult]()
        sut?.save([uniqueItem()]) { receivedResults.append($0) }
        
        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsertion(with: anyNSError())
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    // MARK: Helpers
    
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
    
    private func anyNSError() -> NSError {
        return NSError(domain: "", code: .zero)
    }
    
    private func expect(
        _ sut: LocalFeedLoader,
        toCompleteWithResult expectedResult: LocalFeedLoader.SaveResult,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let items = [uniqueItem(), uniqueItem()]
        let exp = expectation(description: "Wait for save completion")
        
        var receivedResult: LocalFeedLoader.SaveResult?
        sut.save(items) { result in
            receivedResult = result
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1)
        
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

// swiftlint:enable force_unwrapping
