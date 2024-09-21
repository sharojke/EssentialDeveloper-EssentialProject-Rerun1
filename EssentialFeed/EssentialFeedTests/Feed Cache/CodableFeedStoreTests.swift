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
}
