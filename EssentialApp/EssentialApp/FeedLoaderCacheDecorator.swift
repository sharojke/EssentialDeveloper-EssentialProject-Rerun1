import EssentialFeed
import Foundation

public final class FeedLoaderCacheDecorator: FeedLoader {
    private let decoratee: FeedLoader
    private let cache: FeedCache
    
    public init(decoratee: FeedLoader, cache: FeedCache) {
        self.decoratee = decoratee
        self.cache = cache
    }
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        decoratee.load { [weak self] result in
            let mapped = result.map { feed in
                self?.saveIgnoringResult(feed)
                return feed
            }
            completion(mapped)
        }
    }
    
    private func saveIgnoringResult(_ feed: [FeedImage]) {
        cache.save(feed) { _ in }
    }
}
