import Foundation

public final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func save(_ items: [FeedItem], completion: @escaping (Result<Void, Error>) -> Void) {
        store.deleteCachedFeed { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success:
                cache(items, with: completion)
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func cache(_ items: [FeedItem], with completion: @escaping (Result<Void, Error>) -> Void) {
        store.insert(items, timestamp: currentDate()) { [weak self] result in
            guard self != nil else { return }
            
            completion(result)
        }
    }
}
