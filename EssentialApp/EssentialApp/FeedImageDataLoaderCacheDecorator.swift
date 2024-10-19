import EssentialFeed
import Foundation

public final class FeedImageDataLoaderCacheDecorator: FeedImageDataLoader {
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
    
    public init(decoratee: FeedImageDataLoader, cache: FeedImageDataCache) {
        self.decoratee = decoratee
        self.cache = cache
    }
    
    public func loadImageData(
        from url: URL,
        completion: @escaping LoadImageResultCompletion
    ) -> FeedImageDataLoaderTask {
        let task = decoratee.loadImageData(from: url) { [weak self] result in
            let mapped = result.map { data in
                self?.saveIgnoringResult(data, for: url)
                return data
            }
            completion(mapped)
        }
        return TaskWrapper(wrapped: task)
    }
    
    private func saveIgnoringResult(_ data: Data, for url: URL) {
        cache.save(data, for: url) { _ in }
    }
}
