import EssentialApp
import EssentialFeed
import XCTest

private final class FeedImageDataLoaderSpy: FeedImageDataLoader {
    private final class Task: FeedImageDataLoaderTask {
        private let onCancel: () -> Void
        
        init(onCancel: @escaping () -> Void) {
            self.onCancel = onCancel
        }
        
        func cancel() {
            onCancel()
        }
    }
    
    private(set) var loadedURLs = [URL]()
    private(set) var cancelledURLs = [URL]()
    private var loadCompletions = [LoadImageResultCompletion]()
    
    func loadImageData(
        from url: URL,
        completion: @escaping LoadImageResultCompletion
    ) -> FeedImageDataLoaderTask {
        loadedURLs.append(url)
        loadCompletions.append(completion)
        return Task { [weak self] in
            self?.cancelledURLs.append(url)
        }
    }
    
    func completeLoading(with error: Error, at index: Int = .zero) {
        loadCompletions[index](.failure(error))
    }
    
    func completeLoading(with data: Data, at index: Int = .zero) {
        loadCompletions[index](.success(data))
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
    
    func test_cancelLoadImageData_cancelsPrimaryLoaderTask() {
        let (sut, primary, fallback) = makeSUT()
        let url = anyURL()
        
        let task = sut.loadImageData(from: url) { _ in }
        task.cancel()
        
        XCTAssertEqual(primary.cancelledURLs, [url])
        XCTAssertTrue(fallback.cancelledURLs.isEmpty)
    }
    
    func test_cancelLoadImageData_cancelsFallbackLoaderTaskAfterPrimaryLoaderFailure() {
        let (sut, primary, fallback) = makeSUT()
        let url = anyURL()
        
        let task = sut.loadImageData(from: url) { _ in }
        primary.completeLoading(with: anyError())
        task.cancel()
        
        XCTAssertTrue(primary.cancelledURLs.isEmpty)
        XCTAssertEqual(fallback.cancelledURLs, [url])
    }
    
    func test_loadImageData_deliversPrimaryDataOnPrimaryLoaderSuccess() {
        let (sut, primary, fallback) = makeSUT()
        let data = anyData()
        
        expect(sut, toCompleteWith: .success(data)) {
            primary.completeLoading(with: data)
        }
    }
    
    func test_loadImageData_deliversFallbackDataOnFallbackLoaderSuccess() {
        let (sut, primary, fallback) = makeSUT()
        let data = anyData()
        
        expect(sut, toCompleteWith: .success(data)) {
            primary.completeLoading(with: anyError())
            fallback.completeLoading(with: data)
        }
    }
    
    func test_loadImageData_deliversErrorOnBothPrimaryAndFallbackLoaderFailure() {
        let (sut, primary, fallback) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(anyError())) {
            primary.completeLoading(with: anyError())
            fallback.completeLoading(with: anyError())
        }
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
    
    private func expect(
        _ sut: FeedImageDataLoader,
        toCompleteWith expectedResult: FeedImageDataLoader.LoadImageResult,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for load")
        _ = sut.loadImageData(from: anyURL()) { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedData), .success(expectedData)):
                XCTAssertEqual(receivedData, expectedData, file: file, line: line)
                
            case (.failure, .failure):
                break
                
            default:
                XCTFail("Expected \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1)
    }
}
