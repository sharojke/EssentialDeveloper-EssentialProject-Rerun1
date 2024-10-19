import Foundation

public final class LocalFeedLoader: FeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
}

public extension LocalFeedLoader {
    func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(.some(let feed)) where FeedCachePolicy.validate(
                feed.timestamp,
                against: currentDate()
            ):
                completion(.success(feed.feed.models))
                
            case .success:
                completion(.success([]))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

public extension LocalFeedLoader {
    typealias ValidateResult = Result<Void, Error>
    
    func validateCache(completion: @escaping (ValidateResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(.some(let feed)) where FeedCachePolicy.validate(
                feed.timestamp,
                against: currentDate()
            ):
                completion(.success(Void()))
                
            case .success, .failure:
                store.deleteCachedFeed { _ in completion(.success(Void())) }
            }
        }
    }
}
 
public extension LocalFeedLoader {
    typealias SaveResult = Result<Void, Error>
    
    func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
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

private extension Array where Element == LocalFeedImage {
    var models: [FeedImage] {
        return map { local in
            FeedImage(
                id: local.id,
                description: local.description,
                location: local.location,
                url: local.url
            )
        }
    }
}
