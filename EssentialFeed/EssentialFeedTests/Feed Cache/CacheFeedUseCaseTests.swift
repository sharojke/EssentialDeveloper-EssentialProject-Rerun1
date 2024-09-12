import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping

protocol FeedStore {
    typealias DeleteResult = Result<Void, Error>
    typealias InsertResult = Result<Void, Error>
    
    func deleteCachedFeed(completion: @escaping (DeleteResult) -> Void)
    func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping (InsertResult) -> Void)
}

private final class FeedStoreSpy: FeedStore {
    private var deletionCompletions = [(DeleteResult) -> Void]()
    private(set) var insertions = [(items: [FeedItem], timestamp: Date)]()
    
    var deleteCachedFeedCallCount: Int {
        return deletionCompletions.count
    }
    
    var insertCallCount: Int {
        return insertions.count
    }
    
    func deleteCachedFeed(completion: @escaping (DeleteResult) -> Void) {
        deletionCompletions.append(completion)
    }
    
    func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping (InsertResult) -> Void) {
        insertions.append((items, timestamp))
    }
    
    func completeDeletion(with error: Error, at index: Int = .zero) {
        deletionCompletions[index](.failure(error))
    }
    
    func completeDeletionSuccessfully(at index: Int = .zero) {
        deletionCompletions[index](.success(Void()))
    }
}

final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success:
                store.insert(items, timestamp: currentDate()) { _ in }
                
            case .failure:
                break
            }
        }
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
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        let deletionError = anyNSError()
        
        sut.save(items)
        store.completeDeletion(with: deletionError)
        
        XCTAssertTrue(store.insertCallCount == .zero)
    }
    
    func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let items = [uniqueItem(), uniqueItem()]
        
        sut.save(items)
        store.completeDeletionSuccessfully()
        
        XCTAssertTrue(store.insertCallCount == 1)
        XCTAssertTrue(store.insertions.first?.timestamp == timestamp)
        XCTAssertTrue(
            store.insertions.first?.items == items,
            "Expected \(items), received \(store.insertions.first?.items as Any)"
        )
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
}

// swiftlint:enable force_unwrapping
