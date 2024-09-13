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
            let remote = try RemoteFeedItemsMapper.map(data, from: response)
            return .success(remote.toModels())
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

private extension Array where Element == RemoteFeedItem {
    func toModels() -> [FeedItem] {
        return map { remote in
            return FeedItem(
                id: remote.id,
                description: remote.description,
                location: remote.location,
                imageURL: remote.image
            )
        }
    }
}
