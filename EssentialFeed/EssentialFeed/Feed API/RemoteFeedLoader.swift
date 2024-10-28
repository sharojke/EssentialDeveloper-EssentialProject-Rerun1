import Foundation

public final class RemoteFeedLoader: FeedLoader {
    private let url: URL
    private let client: HTTPClient
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        client.get(from: url) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case let .success((data, response)):
                completion(map(data, from: response))
                
            case .failure:
                completion(.failure(LoadError.connectivity))
            }
        }
    }
    
    private func map(_ data: Data, from response: HTTPURLResponse) -> LoadResult {
        do {
            let items = try RemoteFeedImagesMapper.map(data, from: response)
            return .success(items)
        } catch {
            return .failure(error)
        }
    }
}

public extension RemoteFeedLoader {
    enum LoadError: Error {
        case connectivity
        case invalidData
    }
}
