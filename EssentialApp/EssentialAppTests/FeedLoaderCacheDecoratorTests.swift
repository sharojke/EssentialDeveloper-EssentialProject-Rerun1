import EssentialFeed
import XCTest

final class FeedLoaderCacheDecorator: FeedLoader {
    private let decoratee: FeedLoader
    
    init(decoratee: FeedLoader) {
        self.decoratee = decoratee
    }
    
    func load(completion: @escaping (LoadResult) -> Void) {
        decoratee.load(completion: completion)
    }
}

final class FeedLoaderCacheDecoratorTests: XCTestCase {
    func test_load_deliversFeedOnLoaderSuccess() {
        let feed = uniqueFeed()
        let sut = makeSUT(result: .success(feed))
        
        expect(sut, toCompleteWith: .success(feed))
    }
    
    func test_load_deliversErrorOnLoaderFailure() {
        let error = anyNSError()
        let sut = makeSUT(result: .failure(error))
        
        expect(sut, toCompleteWith: .failure(error))
    }
    
    // MARK: Helpers
    
    private func makeSUT(
        result: FeedLoader.LoadResult,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> FeedLoader {
        let loaderStub = FeedLoaderStub(result: result)
        let sut = FeedLoaderCacheDecorator(decoratee: loaderStub)
        trackForMemoryLeaks(loaderStub, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func expect(
        _ sut: FeedLoader,
        toCompleteWith expectedResult: FeedLoader.LoadResult,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for load")
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedFeed), .success(expectedFeed)):
                XCTAssertEqual(receivedFeed, expectedFeed, file: file, line: line)
                
            case (.failure, .failure):
                break
                
            default:
                XCTFail("Expected \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
    }
}
