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
        client.get(from: url) { result in
            switch result {
            case .success:
                completion(.failure(.invalidData))
                
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}
