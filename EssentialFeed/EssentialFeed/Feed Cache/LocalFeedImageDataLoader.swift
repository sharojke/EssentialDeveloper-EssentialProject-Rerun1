import Foundation

private final class LoadImageDataTask: FeedImageDataLoaderTask {
    private var completion: FeedImageDataLoader.LoadImageResultCompletion?

    init(completion: @escaping FeedImageDataLoader.LoadImageResultCompletion) {
        self.completion = completion
    }
    
    func cancel() {
        preventFurtherCompletions()
    }
    
    func complete(with result: FeedImageDataLoader.LoadImageResult) {
        completion?(result)
        preventFurtherCompletions()
    }
    
    private func preventFurtherCompletions() {
        completion = nil
    }
}

public final class LocalFeedImageDataLoader {
    private let store: FeedImageDataStore
    
    public init(store: FeedImageDataStore) {
        self.store = store
    }
}

extension LocalFeedImageDataLoader: FeedImageDataLoader {
    public enum LoadError: Error {
        case failed
        case notFound
    }
    
    public func loadImageData(
        from url: URL,
        completion: @escaping LoadImageResultCompletion
    ) -> FeedImageDataLoaderTask {
        let task = LoadImageDataTask(completion: completion)
        
        do {
            if let data = try store.retrieveData(for: url) {
                task.complete(with: .success(data))
            } else {
                task.complete(with: .failure(LoadError.notFound))
            }
        } catch {
            task.complete(with: .failure(LoadError.failed))
        }
        
        return task
    }
}

extension LocalFeedImageDataLoader: FeedImageDataCache {
    public enum SaveError: Error {
        case failed
    }
    
    public func save(_ data: Data, for url: URL) throws {
        do {
            try store.insert(data, for: url)
        } catch {
            throw SaveError.failed
        }
    }
}
