import Foundation

public final class LocalFeedLoader {
    public typealias SaveResult = Result<Void, Error>
    
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success:
                cache(feed, with: completion)
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func cache(_ feed: [FeedImage], with completion: @escaping (SaveResult) -> Void) {
        let local = feed.map(\.local)
        store.insert(local, timestamp: currentDate()) { [weak self] result in
            guard self != nil else { return }
            
            completion(result)
        }
    }
}

private extension FeedImage {
    var local: LocalFeedImage {
        return LocalFeedImage(
            id: id,
            description: description,
            location: location,
            url: url
        )
    }
}
