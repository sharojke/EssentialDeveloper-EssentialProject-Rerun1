import Foundation

public enum RemoteFeedLoaderError {
    case connectivity
}

public final class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping (RemoteFeedLoaderError) -> Void = { _ in }) {
        client.get(from: url) { _ in
            completion(.connectivity)
        }
    }
}
