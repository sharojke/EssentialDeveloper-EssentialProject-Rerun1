import Foundation

public typealias RemoteFeedLoaderResult = Result<[FeedItem], RemoteFeedLoaderError>

public enum RemoteFeedLoaderError: Error {
    case connectivity
    case invalidData
}

public final class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping (RemoteFeedLoaderResult) -> Void) {
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            
            switch result {
            case let .success((data, response)):
                completion(RemoteFeedItemsMapper.map(data, from: response))
                
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}
