import Foundation

public final class RemoteFeedLoader: FeedLoader {
    public typealias LoadResult = FeedLoader.LoadResult
    
    private let url: URL
    private let client: HTTPClient
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            
            switch result {
            case let .success((data, response)):
                completion(RemoteFeedItemsMapper.map(data, from: response))
                
            case .failure:
                completion(.failure(LoadError.connectivity))
            }
        }
    }
}

public extension RemoteFeedLoader {
    enum LoadError: Error {
        case connectivity
        case invalidData
    }
}
