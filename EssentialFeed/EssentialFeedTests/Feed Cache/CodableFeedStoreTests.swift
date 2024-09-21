import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping
// swiftlint:disable force_try

final class CodableFeedStore: FeedStore {
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date
        
        var localFeed: LocalFeed {
            return LocalFeed(feed: feed.map(\.local), timestamp: timestamp)
        }
    }
    
    private struct CodableFeedImage: Equatable, Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL
        
        init(_ image: LocalFeedImage) {
            id = image.id
            description = image.description
            location = image.location
            url = image.url
        }
        
        var local: LocalFeedImage {
            return LocalFeedImage(id: id, description: description, location: location, url: url)
        }
    }
    
    private let storeURL: URL
    
    init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    func deleteCachedFeed(completion: @escaping (DeleteResult) -> Void) {
        guard FileManager.default.fileExists(atPath: storeURL.path()) else {
            return completion(.success(Void()))
        }
        
        do {
            try FileManager.default.removeItem(at: storeURL)
            completion(.success(Void()))
        } catch {
            completion(.failure(error))
        }
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping (InsertResult) -> Void) {
        do {
            let encoder = JSONEncoder()
            let localFeed = Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp)
            let encoded = try! encoder.encode(localFeed)
            try encoded.write(to: storeURL)
            completion(.success(Void()))
        } catch {
            completion(.failure(error))
        }
    }
    
    func retrieve(completion: @escaping (RetrieveResult) -> Void) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.success(LocalFeed(feed: [], timestamp: Date())))
        }
        
        do {
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(Cache.self, from: data)
            completion(.success(decoded.localFeed))
        } catch {
            completion(.failure(error))
        }
    }
}

final class CodableFeedStoreTests: XCTestCase {
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
    
    func test_insert_overridesPreviouslyInsertedCachedValues() {
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
    
    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        
        expect(sut, toDeleteCacheFeed: .success(Void()))

        expect(sut, toRetrieveTwice: .success(LocalFeed(feed: [], timestamp: Date())))
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
        
        expect(sut, toRetrieveTwice: .success(LocalFeed(feed: [], timestamp: Date())))
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
    
    private func expect(
        _ sut: FeedStore,
        toRetrieve expectedResult: FeedStore.RetrieveResult,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for retrieval")

        sut.retrieve { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedFeed), .success(expectedFeed)):
                XCTAssertEqual(receivedFeed.feed, expectedFeed.feed, file: file, line: line)
//                XCTAssertEqual(receivedFeed.timestamp, expectedFeed.timestamp, file: file, line: line)
                
            case (.failure, .failure):
                break
                
            default:
                XCTFail(
                    "Expected \(expectedResult), got \(receivedResult) instead",
                    file: file,
                    line: line
                )
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
    }
    
    private func expect(
        _ sut: FeedStore,
        toRetrieveTwice expectedResult: FeedStore.RetrieveResult,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }
    
    private func expect(
        _ sut: FeedStore,
        toInsertFeed feed: [LocalFeedImage],
        withTimestamp timestamp: Date,
        andCompleteWith expectedResult: FeedStore.InsertResult,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for insert")
        sut.insert(feed, timestamp: timestamp) { receivedResult in
            switch (receivedResult, expectedResult) {
            case (.success, .success), (.failure, .failure):
                break
                
            default:
                XCTFail(
                    "Expected \(expectedResult), got \(receivedResult) instead",
                    file: file,
                    line: line
                )
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    private func expect(
        _ sut: FeedStore,
        toDeleteCacheFeed expectedResult: FeedStore.DeleteResult,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for delete cache feed")

        sut.deleteCachedFeed { receivedResult in
            switch (receivedResult, expectedResult) {
            case (.success, .success), (.failure, .failure):
                break
                
            default:
                XCTFail(
                    "Expected \(expectedResult), got \(receivedResult) instead",
                    file: file,
                    line: line
                )
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
    }
    
    private func insert(
        feed: [LocalFeedImage],
        timestamp: Date,
        to sut: FeedStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        expect(
            sut,
            toInsertFeed: feed,
            withTimestamp: timestamp,
            andCompleteWith: .success(Void()),
            file: file,
            line: line
        )
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
