import Foundation

public final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
}

public extension LocalFeedLoader {
    typealias LoadResult = Result<[FeedImage], Error>
    
    func load() throws -> [FeedImage] {
        if let cache = try store.retrieve(),
           FeedCachePolicy.validate(cache.timestamp, against: currentDate()) {
            return cache.feed.models
        }
        
        return []
    }
}

public extension LocalFeedLoader {
    private struct InvalidCache: Error {}
    
    func validateCache() throws {
        do {
            if let cache = try store.retrieve(),
               !FeedCachePolicy.validate(cache.timestamp, against: currentDate()) {
                throw InvalidCache()
            }
        } catch {
            try store.deleteCachedFeed()
        }
    }
}
 
extension LocalFeedLoader: FeedCache {
    public func save(_ feed: [FeedImage]) throws {
        try store.deleteCachedFeed()
        try store.insert(feed.map(\.local), timestamp: currentDate())
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
