import EssentialFeed
import XCTest

private final class FeedImageDataCacheSpy: FeedImageDataCache {
    enum Message: Equatable {
        case save(Data, for: URL)
    }
    
    private(set) var messages = [Message]()
    private var saveCompletions = [SaveCompletion]()
    
    func save(_ data: Data, for url: URL, completion: @escaping SaveCompletion) {
        messages.append(.save(data, for: url))
        saveCompletions.append(completion)
    }
    
    func completeSaving(with error: Error, at index: Int = .zero) {
        saveCompletions[index](.failure(error))
    }
    
    func completeSavingSuccessfully(at index: Int = .zero) {
        saveCompletions[index](.success(Void()))
    }
}

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
    private let cache: FeedImageDataCache
    
    init(decoratee: FeedImageDataLoader, cache: FeedImageDataCache) {
        self.decoratee = decoratee
        self.cache = cache
    }
    
    func loadImageData(
        from url: URL,
        completion: @escaping LoadImageResultCompletion
    ) -> FeedImageDataLoaderTask {
        let task = decoratee.loadImageData(from: url) { [weak self] result in
            let mapped = result.map { data in
                self?.cache.save(data, for: url) { _ in }
                return data
            }
            completion(mapped)
        }
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
    
    func test_loadImageData_deliversErrorOnLoaderFailure() {
        let (sut, loader) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(anyError())) {
            loader.completeLoading(with: anyError())
        }
    }
    
    func test_loadImageData_cachesLoadedDataOnLoaderSuccess() {
        let cache = FeedImageDataCacheSpy()
        let (sut, loader) = makeSUT(cache: cache)
        let url = anyURL()
        let data = anyData()
        
        _ = sut.loadImageData(from: url) { _ in }
        loader.completeLoading(with: data)
        
        XCTAssertEqual(cache.messages, [.save(data, for: url)])
    }
    
    func test_loadImageData_doesNotCacheDataOnLoaderFailure() {
        let cache = FeedImageDataCacheSpy()
        let (sut, loader) = makeSUT(cache: cache)
        
        _ = sut.loadImageData(from: anyURL()) { _ in }
        loader.completeLoading(with: anyError())
        
        XCTAssertTrue(cache.messages.isEmpty)
    }
    
    // MARK: Helpers
    
    private func makeSUT(
        cache: FeedImageDataCache = FeedImageDataCacheSpy(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: FeedImageDataLoader, loader: FeedImageDataLoaderSpy) {
        let loaderSpy = FeedImageDataLoaderSpy()
        let sut = FeedImageDataLoaderCacheDecorator(decoratee: loaderSpy, cache: cache)
        trackForMemoryLeaks(loaderSpy, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loaderSpy)
    }
}
