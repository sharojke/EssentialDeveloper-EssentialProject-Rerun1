import EssentialFeed
import XCTest

final class CodableFeedStore {
    typealias RetrieveResult = FeedStore.RetrieveResult
    
    func retrieve(completion: @escaping (RetrieveResult) -> Void) {
        completion(.success(LocalFeed(feed: [], timestamp: Date())))
    }
}

final class CodableFeedStoreTests: XCTestCase {
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
}
