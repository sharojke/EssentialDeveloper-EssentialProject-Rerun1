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
    
    @discardableResult
    public func loadImageData(
        from url: URL,
        completion: @escaping LoadImageResultCompletion
    ) -> FeedImageDataLoaderTask {
        let taskWrapper = HTTPTaskWrapper(completion: completion)
        let task = client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            
            let taskResult: FeedImageDataLoader.LoadImageResult
            defer { taskWrapper.complete(with: taskResult) }
            
            switch result {
            case let .success((data, response)):
                guard response.statusCode == 200,
                      !data.isEmpty else {
                    taskResult = .failure(Error.invalidData)
                    return
                }
                
                taskResult = .success(data)
                
            case .failure:
                taskResult = .failure(Error.connectivity)
            }
        }
        taskWrapper.wrapped = task
        return taskWrapper
    }
}
