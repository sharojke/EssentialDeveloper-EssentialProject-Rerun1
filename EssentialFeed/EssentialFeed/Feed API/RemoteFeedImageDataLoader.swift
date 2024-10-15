import Foundation

private final class HTTPTaskWrapper: FeedImageDataLoaderTask {
    private var completion: FeedImageDataLoader.LoadImageResultCompletion?
    var wrapped: HTTPClientTask?
    
    init(completion: @escaping FeedImageDataLoader.LoadImageResultCompletion) {
        self.completion = completion
    }
    
    func complete(with result: FeedImageDataLoader.LoadImageResult) {
        completion?(result)
    }
    
    func cancel() {
        preventFurtherCompletions()
        wrapped?.cancel()
        wrapped = nil
    }
    
    private func preventFurtherCompletions() {
        completion = nil
    }
}

public final class RemoteFeedImageDataLoader: FeedImageDataLoader {
    public enum Error: Swift.Error {
        case invalidData
        case connectivity
    }
    
    private let client: HTTPClient

    public init(client: HTTPClient) {
        self.client = client
    }
    
    public func loadImageData(
        from url: URL,
        completion: @escaping LoadImageResultCompletion
    ) -> FeedImageDataLoaderTask {
        let taskWrapper = HTTPTaskWrapper(completion: completion)
        let task = client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            
            let mappedResult = result
                .mapError { _ in Error.connectivity }
                .flatMap { data, response -> LoadImageResult in
                    let isValidResponse = response.isOK && !data.isEmpty
                    return isValidResponse ? .success(data) : .failure(Error.invalidData)
                }
            taskWrapper.complete(with: mappedResult)
        }
        taskWrapper.wrapped = task
        return taskWrapper
    }
}
