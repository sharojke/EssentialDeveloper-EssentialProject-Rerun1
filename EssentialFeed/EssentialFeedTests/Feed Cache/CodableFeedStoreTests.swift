import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping
// swiftlint:disable force_try

final class CodableFeedStore {
    typealias RetrieveResult = FeedStore.RetrieveResult
    typealias InsertResult = FeedStore.InsertResult
    
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
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping (InsertResult) -> Void) {
        let encoder = JSONEncoder()
        let localFeed = Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp)
        let encoded = try! encoder.encode(localFeed)
        try! encoded.write(to: storeURL)
        
        completion(.success(Void()))
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
        let sut = makeSUT()
        
        try! "invalid data".write(to: testSpecificStoreURL(), atomically: false, encoding: .utf8)
        
        expect(sut, toRetrieve: .failure(anyNSError()))
    }
    
    // MARK: Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(storeURL: testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func expect(
        _ sut: CodableFeedStore,
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
        _ sut: CodableFeedStore,
        toRetrieveTwice expectedResult: FeedStore.RetrieveResult,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }
    
    private func insert(
        feed: [LocalFeedImage],
        timestamp: Date,
        to sut: CodableFeedStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for insert")
        sut.insert(feed, timestamp: timestamp) { result in
            switch result {
            case .success:
                exp.fulfill()
                
            case .failure(let error):
                XCTFail("Expected success, got \(error) instead")
            }
        }
        wait(for: [exp], timeout: 1)
    }
    
    private func testSpecificStoreURL() -> URL {
        return FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("\(type(of: self)).store")
    }
    
    private func removeStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
}

// swiftlint:enable force_unwrapping
// swiftlint:enable force_try
