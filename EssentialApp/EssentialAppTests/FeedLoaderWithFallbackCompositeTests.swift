import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping

private final class FeedLoaderWithFallbackComposite: FeedLoader {
    private let primary: FeedLoader
    private let fallback: FeedLoader
    
    init(primary: FeedLoader, fallback: FeedLoader) {
        self.primary = primary
        self.fallback = fallback
    }
    
    func load(completion: @escaping (LoadResult) -> Void) {
        primary.load(completion: completion)
    }
}

private final class LoaderStub: FeedLoader {
    private let result: LoadResult
    
    init(result: LoadResult) {
        self.result = result
    }
    
    func load(completion: @escaping (LoadResult) -> Void) {
        completion(result)
    }
}

final class FeedLoaderWithFallbackCompositeTests: XCTestCase {
    func test_load_deliversPrimaryFeedOnPrimaryLoaderSuccess() {
        let primaryFeed = uniqueFeed()
        let sut = makeSUT(primaryResult: .success(primaryFeed), fallbackResult: .success([]))
        
        let exp = expectation(description: "Wait for load")
        sut.load { result in
            switch result {
            case .success(let receivedFeed):
                XCTAssertEqual(receivedFeed, primaryFeed)
                
            case .failure(let error):
                XCTFail("Expected success, got \(error) instead")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
    }
    
    // MARK: Helpers
    
    private func makeSUT(
        primaryResult: FeedLoader.LoadResult,
        fallbackResult: FeedLoader.LoadResult,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> FeedLoader {
        let primary = LoaderStub(result: primaryResult)
        let fallback = LoaderStub(result: fallbackResult)
        let sut = FeedLoaderWithFallbackComposite(primary: primary, fallback: fallback)
        trackForMemoryLeaks(primary, file: file, line: line)
        trackForMemoryLeaks(fallback, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func uniqueFeed() -> [FeedImage] {
        let image = FeedImage(
            id: UUID(),
            description: "a description",
            location: "a location",
            url: URL(string: "http://a-url.com")!
        )
        return [image]
    }
}

// swiftlint:enable force_unwrapping
