import EssentialFeed
import XCTest

private final class FeedImageDataLoaderWithFallbackComposite: FeedImageDataLoader {
    private let primary: FeedImageDataLoader
    private let fallback: FeedImageDataLoader
    
    init(primary: FeedImageDataLoader, fallback: FeedImageDataLoader) {
        self.primary = primary
        self.fallback = fallback
    }
    
    func loadImageData(
        from url: URL,
        completion: @escaping LoadImageResultCompletion
    ) -> FeedImageDataLoaderTask {
        return primary.loadImageData(from: url) { [weak self] primaryResult in
            switch primaryResult {
            case .success:
                completion(primaryResult)
                
            case .failure:
                _ = self?.fallback.loadImageData(from: url, completion: completion)
            }
        }
    }
}

private final class FeedImageDataLoaderSpy: FeedImageDataLoader {
    private final class Task: FeedImageDataLoaderTask {
        func cancel() {}
    }
    
    private(set) var loadedURLs = [URL]()
    private var loadCompletions = [LoadImageResultCompletion]()
    
    func loadImageData(
        from url: URL,
        completion: @escaping LoadImageResultCompletion
    ) -> FeedImageDataLoaderTask {
        loadedURLs.append(url)
        loadCompletions.append(completion)
        return Task()
    }
    
    func completeLoading(with error: Error, at index: Int = .zero) {
        loadCompletions[index](.failure(error))
    }
}

// swiftlint:disable:next type_name
final class FeedImageDataLoaderWithFallbackCompositeTests: XCTestCase {
    func test_init_doesNotLoadImage() {
        let (_, primary, fallback) = makeSUT()
        
        XCTAssertTrue(primary.loadedURLs.isEmpty)
        XCTAssertTrue(fallback.loadedURLs.isEmpty)
    }
    
    func test_loadImageData_loadsFromPrimaryLoaderFirst() {
        let (sut, primary, fallback) = makeSUT()
        let url = anyURL()
        
        _ = sut.loadImageData(from: url) { _ in }
        
        XCTAssertEqual(primary.loadedURLs, [url])
        XCTAssertTrue(fallback.loadedURLs.isEmpty)
    }
    
    func test_loadImageData_loadsFromFallbackOnPrimaryLoaderFailure() {
        let (sut, primary, fallback) = makeSUT()
        let url = anyURL()
        
        _ = sut.loadImageData(from: url) { _ in }
        primary.completeLoading(with: anyError())
        
        XCTAssertEqual(primary.loadedURLs, [url])
        XCTAssertEqual(fallback.loadedURLs, [url])
    }
    
    // MARK: Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
        // swiftlint:disable:next large_tuple
    ) -> (sut: FeedImageDataLoader, primary: FeedImageDataLoaderSpy, fallback: FeedImageDataLoaderSpy) {
        let primary = FeedImageDataLoaderSpy()
        let fallback = FeedImageDataLoaderSpy()
        let sut = FeedImageDataLoaderWithFallbackComposite(primary: primary, fallback: fallback)
        trackForMemoryLeaks(primary, file: file, line: line)
        trackForMemoryLeaks(fallback, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, primary, fallback)
    }
}
