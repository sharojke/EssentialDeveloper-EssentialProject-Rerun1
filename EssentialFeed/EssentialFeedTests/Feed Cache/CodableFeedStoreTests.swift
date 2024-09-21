import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping
// swiftlint:disable force_try

final class CodableFeedStore {
    typealias RetrieveResult = FeedStore.RetrieveResult
    typealias InsertResult = FeedStore.InsertResult
    
    private let storeURL = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask).first!
        .appendingPathComponent("image-feed.store")
    
    func retrieve(completion: @escaping (RetrieveResult) -> Void) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.success(LocalFeed(feed: [], timestamp: Date())))
        }
                              
        let decoder = JSONDecoder()
        let decoded = try! decoder.decode(LocalFeed.self, from: data)
        completion(.success(decoded))
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping (InsertResult) -> Void) {
        let encoder = JSONEncoder()
        let localFeed = LocalFeed(feed: feed, timestamp: timestamp)
        let encoded = try! encoder.encode(localFeed)
        try! encoded.write(to: storeURL)
        
        completion(.success(Void()))
    }
}

final class CodableFeedStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        
        let storeURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }
    
    override func tearDown() {
        super.tearDown()
        
        let storeURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = CodableFeedStore()
        let exp = expectation(description: "Wait for retrieval")

        sut.retrieve { result in
            switch result {
            case .success(let feed):
                XCTAssertEqual(feed.feed, [])
                
            case .failure(let error):
                XCTFail("Expected empty feed, got \(error) instead")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = CodableFeedStore()
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
        let sut = CodableFeedStore()
        let exp = expectation(description: "Wait for retrieval")
        let feed = uniqueFeed().local
        let date = Date()

        sut.insert(feed, timestamp: date) { insertResult in
            switch insertResult {
            case .success:
                sut.retrieve { retrieveResult in
                    switch retrieveResult {
                    case .success(let receivedFeed):
                        XCTAssertEqual(receivedFeed.feed, feed)
                        XCTAssertEqual(receivedFeed.timestamp, date)
                        
                    case .failure(let error):
                        XCTFail("Expected \(feed), got \(error) instead")
                    }
                    
                    exp.fulfill()
                }
                
            case .failure(let error):
                XCTFail("Expected success, got \(error) instead")
            }
        }
        
        wait(for: [exp], timeout: 1)
    }
}

// swiftlint:enable force_unwrapping
// swiftlint:enable force_try
