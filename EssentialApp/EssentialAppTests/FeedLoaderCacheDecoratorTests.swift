import EssentialApp
import EssentialFeed
import XCTest

private final class FeedCacheSpy: FeedCache {
    enum Message: Equatable {
        case save([FeedImage])
    }
    
    private(set) var messages = [Message]()
    private var saveCompletions = [SaveCompletion]()
    
    func save(_ feed: [FeedImage], completion: @escaping SaveCompletion) {
        messages.append(.save(feed))
        saveCompletions.append(completion)
    }
}

final class FeedLoaderCacheDecoratorTests: XCTestCase, FeedLoaderTestCase {
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
    
    func test_load_cachesLoadedFeedOnLoaderSuccess() {
        let cache = FeedCacheSpy()
        let feed = uniqueFeed()
        let sut = makeSUT(result: .success(feed), cache: cache)
        
        sut.load { _ in }
        
        XCTAssertEqual(cache.messages, [.save(feed)])
    }
    
    func test_load_doesNotCacheOnLoaderFailure() {
        let cache = FeedCacheSpy()
        let sut = makeSUT(result: .failure(anyError()), cache: cache)
        
        sut.load { _ in }
        
        XCTAssertEqual(cache.messages, [])
    }
    
    // MARK: Helpers
    
    private func makeSUT(
        result: FeedLoader.LoadResult,
        cache: FeedCache = FeedCacheSpy(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> FeedLoader {
        let loaderStub = FeedLoaderStub(result: result)
        let sut = FeedLoaderCacheDecorator(decoratee: loaderStub, cache: cache)
        trackForMemoryLeaks(loaderStub, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}
