import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping
// swiftlint:disable force_try

final class CodableFeedStoreTests: XCTestCase, FailableFeedStoreSpecs {
    override func setUp() {
        super.setUp()
        
        removeStoreArtifacts()
    }
    
    override func tearDown() {
        super.tearDown()
        
        removeStoreArtifacts()
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
        
        expect(sut, toRetrieve: .success(LocalFeed(feed: [], timestamp: Date())))
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()

        expect(sut, toRetrieveTwice: .success(LocalFeed(feed: [], timestamp: Date())))
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueFeed().local
        let date = Date()

        insert(feed: feed, timestamp: date, to: sut)
        
        expect(sut, toRetrieve: .success(LocalFeed(feed: feed, timestamp: date)))
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueFeed().local
        let date = Date()

        insert(feed: feed, timestamp: date, to: sut)
        
        expect(sut, toRetrieveTwice: .success(LocalFeed(feed: feed, timestamp: date)))
    }
    
    func test_retrieve_deliversErrorOnRetrievalError() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        expect(sut, toRetrieve: .failure(anyNSError()))
    }
    
    func test_retrieve_hasNoSideEffectsOnFailure() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        expect(sut, toRetrieveTwice: .failure(anyNSError()))
    }
    
    func test_insert_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()
        
        insert(feed: uniqueFeed().local, timestamp: Date(), to: sut)
    }
    
    func test_insert_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()
        insert(feed: uniqueFeed().local, timestamp: Date(), to: sut)
        
        insert(feed: uniqueFeed().local, timestamp: Date(), to: sut)
    }
    
    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let sut = makeSUT()

        insert(feed: uniqueFeed().local, timestamp: Date(), to: sut)
        
        let latestFeed = uniqueFeed().local
        let latestDate = Date()
        insert(feed: latestFeed, timestamp: latestDate, to: sut)
        
        expect(sut, toRetrieve: .success(LocalFeed(feed: latestFeed, timestamp: latestDate)))
    }
    
    func test_insert_deliversErrorOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidStoreURL)
        
        expect(
            sut,
            toInsertFeed: uniqueFeed().local,
            withTimestamp: Date(),
            andCompleteWith: .failure(anyNSError())
        )
    }
    
    func test_insert_hasNoSideEffectsOnFailure() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidStoreURL)
                
        expect(
            sut,
            toInsertFeed: uniqueFeed().local,
            withTimestamp: Date(),
            andCompleteWith: .failure(anyNSError())
        )
        
        expect(sut, toRetrieve: .success(LocalFeed(feed: [], timestamp: Date())))
    }
    
    func test_delete_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()
        
        expect(sut, toDeleteCacheFeed: .success(Void()))
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        
        expect(sut, toDeleteCacheFeed: .success(Void()))

        expect(sut, toRetrieveTwice: .success(LocalFeed(feed: [], timestamp: Date())))
    }
    
    func test_delete_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()
        
        insert(feed: uniqueFeed().local, timestamp: Date(), to: sut)
        
        expect(sut, toDeleteCacheFeed: .success(Void()))
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()
        
        insert(feed: uniqueFeed().local, timestamp: Date(), to: sut)
        expect(sut, toDeleteCacheFeed: .success(Void()))
        
        expect(sut, toRetrieveTwice: .success(LocalFeed(feed: [], timestamp: Date())))
    }
    
    func test_delete_deliversErrorOnDeletionError() {
        let sut = makeSUT(storeURL: cachesDirectory())
        
        expect(sut, toDeleteCacheFeed: .failure(anyNSError()))
    }
    
    func test_delete_hasNoSideEffectsOnFailure() {
        let sut = makeSUT(storeURL: cachesDirectory())
        
        expect(sut, toDeleteCacheFeed: .failure(anyNSError()))
        
        expect(sut, toRetrieve: .success(LocalFeed(feed: [], timestamp: Date())))
    }
    
    func test_storeSideEffects_runSerially() {
        let sut = makeSUT()
        var completedOperationsInOrder = [XCTestExpectation]()
        
        let operation1 = expectation(description: "Operation 1")
        sut.insert(uniqueFeed().local, timestamp: Date()) { _ in
            completedOperationsInOrder.append(operation1)
            operation1.fulfill()
        }
        
        let operation2 = expectation(description: "Operation 2")
        sut.deleteCachedFeed { _ in
            completedOperationsInOrder.append(operation2)
            operation2.fulfill()
        }
        
        let operation3 = expectation(description: "Operation 3")
        sut.insert(uniqueFeed().local, timestamp: Date()) { _ in
            completedOperationsInOrder.append(operation3)
            operation3.fulfill()
        }
        
        waitForExpectations(timeout: 5)
        XCTAssertEqual(completedOperationsInOrder, [operation1, operation2, operation3], "The order is wrong")
    }
    
    // MARK: Helpers
    
    private func makeSUT(
        storeURL: URL? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> FeedStore {
        let storeURL = storeURL ?? testSpecificStoreURL()
        let sut = CodableFeedStore(storeURL: storeURL)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func testSpecificStoreURL() -> URL {
        return cachesDirectory().appendingPathComponent("\(type(of: self)).store")
    }
    
    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    private func removeStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
}

// swiftlint:enable force_unwrapping
// swiftlint:enable force_try
