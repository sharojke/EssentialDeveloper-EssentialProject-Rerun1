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
        primary.load { [weak self] primaryResult in
            switch primaryResult {
            case .success(let feed):
                completion(.success(feed))
                
            case .failure:
                self?.fallback.load(completion: completion)
            }
        }
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
        
        expect(sut, toCompleteWith: .success(primaryFeed))
    }
    
    func test_load_deliversFallbackFeedOnPrimaryLoaderFailure() {
        let fallbackFeed = uniqueFeed()
        let sut = makeSUT(primaryResult: .failure(anyError()), fallbackResult: .success(fallbackFeed))
        
        expect(sut, toCompleteWith: .success(fallbackFeed))
    }
    
    func test_load_deliversErrorOnBothPrimaryAndFallbackLoadersFailure() {
        let fallbackFeed = uniqueFeed()
        let sut = makeSUT(primaryResult: .failure(anyError()), fallbackResult: .failure(anyError()))
        
        expect(sut, toCompleteWith: .failure(anyError()))
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
