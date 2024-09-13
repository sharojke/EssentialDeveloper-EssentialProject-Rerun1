import Foundation

public final class LocalFeedLoader {
    public typealias SaveResult = Result<Void, Error>
    
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func save(_ items: [FeedItem], completion: @escaping (SaveResult) -> Void) {
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
    
    private func cache(_ items: [FeedItem], with completion: @escaping (SaveResult) -> Void) {
        let localItems = items.map(\.local)
        store.insert(localItems, timestamp: currentDate()) { [weak self] result in
            guard self != nil else { return }
            
            completion(result)
        }
    }
}

private extension FeedItem {
    var local: LocalFeedItem {
        return LocalFeedItem(
            id: id,
            description: description,
            location: location,
            imageURL: imageURL
        )
    }
}
