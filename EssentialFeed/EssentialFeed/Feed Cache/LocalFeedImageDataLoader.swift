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

public extension LocalFeedImageDataLoader {
    typealias SaveImageResult = Result<Void, Error>
    typealias SaveImageResultCompletion = (SaveImageResult) -> Void
    
    enum SaveError: Error {
        case failed
    }
    
    func save(_ data: Data, for url: URL, completion: @escaping SaveImageResultCompletion) {
        store.insert(data, for: url) { _ in
            completion(.failure(SaveError.failed))
        }
    }
}
