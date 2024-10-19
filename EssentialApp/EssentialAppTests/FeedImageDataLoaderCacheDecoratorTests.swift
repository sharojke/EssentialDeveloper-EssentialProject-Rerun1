import EssentialFeed
import XCTest

final class FeedImageDataLoaderCacheDecorator: FeedImageDataLoader {
    private final class TaskWrapper: FeedImageDataLoaderTask {
        private var wrapped: FeedImageDataLoaderTask?
        
        init(wrapped: FeedImageDataLoaderTask) {
            self.wrapped = wrapped
        }
        
        func cancel() {
            wrapped?.cancel()
            wrapped = nil
        }
    }
    
    private let decoratee: FeedImageDataLoader
    
    init(decoratee: FeedImageDataLoader) {
        self.decoratee = decoratee
    }
    
    func loadImageData(
        from url: URL,
        completion: @escaping LoadImageResultCompletion
    ) -> FeedImageDataLoaderTask {
        let task = decoratee.loadImageData(from: url, completion: completion)
        return TaskWrapper(wrapped: task)
    }
}

final class FeedImageDataLoaderCacheDecoratorTests: XCTestCase, FeedImageDataLoaderTestCase {
    func test_init_doesNotLoadImageData() {
        let (_, loader) = makeSUT()
        
        XCTAssertTrue(loader.loadedURLs.isEmpty)
    }
    
    func test_loadImageData_loadsFromLoader() {
        let (sut, loader) = makeSUT()
        let url = anyURL()
        
        _ = sut.loadImageData(from: url) { _ in }
        
        XCTAssertEqual(loader.loadedURLs, [url])
    }
    
    func test_cancelLoadImageData_cancelsLoaderTask() {
        let (sut, loader) = makeSUT()
        let url = anyURL()
        
        let task = sut.loadImageData(from: url) { _ in }
        task.cancel()
        
        XCTAssertEqual(loader.cancelledURLs, [url])
    }
    
    func test_loadImageData_deliversDataOnLoaderSuccess() {
        let (sut, loader) = makeSUT()
        let data = anyData()
        
        expect(sut, toCompleteWith: .success(data)) {
            loader.completeLoading(with: data)
        }
    }

    // MARK: Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: FeedImageDataLoader, loader: FeedImageDataLoaderSpy) {
        let loaderSpy = FeedImageDataLoaderSpy()
        let sut = FeedImageDataLoaderCacheDecorator(decoratee: loaderSpy)
        trackForMemoryLeaks(loaderSpy, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loaderSpy)
    }
}
