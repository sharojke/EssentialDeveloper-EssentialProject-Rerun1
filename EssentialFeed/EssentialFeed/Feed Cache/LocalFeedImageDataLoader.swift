import Foundation

private final class Task: FeedImageDataLoaderTask {
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

public final class LocalFeedImageDataLoader: FeedImageDataLoader {
    public enum LoadError: Error {
        case failed
        case notFound
    }
    
    private let store: FeedImageDataStore
    
    public init(store: FeedImageDataStore) {
        self.store = store
    }
    
    public func loadImageData(
        from url: URL,
        completion: @escaping LoadImageResultCompletion
    ) -> FeedImageDataLoaderTask {
        let task = Task(completion: completion)
        store.retrieveData(for: url) { [weak self] result in
            guard self != nil else { return }
            
            let mapped = result
                .mapError { _ in LoadError.failed }
                .flatMap { $0.map(LoadImageResult.success) ?? .failure(LoadError.notFound) }
            task.complete(with: mapped)
        }
        return task
    }
}
