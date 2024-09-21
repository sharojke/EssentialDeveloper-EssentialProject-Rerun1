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
                              
        let decoder = JSONDecoder()
        let decoded = try! decoder.decode(Cache.self, from: data)
        completion(.success(decoded.localFeed))
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
        let exp = expectation(description: "Wait for retrieval")

        sut.retrieve { firstResult in
            sut.retrieve { secondResult in
                switch (firstResult, secondResult) {
                case let (.success(firstFeed), .success(secondFeed)):
                    XCTAssertEqual(firstFeed.feed, [])
                    XCTAssertEqual(secondFeed.feed, [])
                    
                default:
                    XCTFail("Expected empty feed twice, got \(firstResult) and \(secondResult) instead")
                }
                
                exp.fulfill()
            }
        }
        
        wait(for: [exp], timeout: 1)
    }
    
    func test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues() {
        let sut = makeSUT()
        let feed = uniqueFeed().local
        let date = Date()

        let exp = expectation(description: "Wait for retrieval")
        sut.insert(feed, timestamp: date) { insertResult in
            switch insertResult {
            case .success:
                exp.fulfill()
                
            case .failure(let error):
                XCTFail("Expected success, got \(error) instead")
            }
        }
        wait(for: [exp], timeout: 1)
        
        expect(sut, toRetrieve: .success(LocalFeed(feed: feed, timestamp: date)))
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        let exp = expectation(description: "Wait for retrieval")
        let feed = uniqueFeed().local
        let date = Date()

        sut.insert(feed, timestamp: date) { insertResult in
            switch insertResult {
            case .success:
                sut.retrieve { firstResult in
                    sut.retrieve { secondResult in
                        switch (firstResult, secondResult) {
                        case let (.success(firstFeed), .success(secondFeed)):
                            XCTAssertEqual(firstFeed.feed, feed)
                            XCTAssertEqual(firstFeed.timestamp, date)
                            
                            XCTAssertEqual(secondFeed.feed, feed)
                            XCTAssertEqual(secondFeed.timestamp, date)
                            
                        default:
                            XCTFail("Expected \(feed), got \(firstResult) and \(secondResult) instead")
                        }
                        
                        exp.fulfill()
                    }
                }
                
            case .failure(let error):
                XCTFail("Expected success, got \(error) instead")
            }
        }
        
        wait(for: [exp], timeout: 1)
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
