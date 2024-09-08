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
    
    private static func map(_ data: Data, from response: HTTPURLResponse) -> RemoteFeedLoaderResult {
        do {
            let items = try RemoteFeedItemsMapper.map(data: data, response: response)
            return .success(items)
        } catch {
            return .failure(.invalidData)
        }
    }
    
    public func load(completion: @escaping (RemoteFeedLoaderResult) -> Void) {
        client.get(from: url) { result in
            switch result {
            case let .success((data, response)):
                completion(Self.map(data, from: response))
                
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}
