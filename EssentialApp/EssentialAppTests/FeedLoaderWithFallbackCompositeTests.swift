import EssentialApp
import EssentialFeed
import XCTest

final class FeedLoaderWithFallbackCompositeTests: XCTestCase, FeedLoaderTestCase {
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
        let primary = FeedLoaderStub(result: primaryResult)
        let fallback = FeedLoaderStub(result: fallbackResult)
        let sut = FeedLoaderWithFallbackComposite(primary: primary, fallback: fallback)
        trackForMemoryLeaks(primary, file: file, line: line)
        trackForMemoryLeaks(fallback, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}
