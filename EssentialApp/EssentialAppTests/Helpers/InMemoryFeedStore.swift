import EssentialFeed
import Foundation

final class InMemoryFeedStore {
    private(set) var feedCache: CachedFeed?
    private var feedImageDataCache = [URL: Data]()
    
    private init(feedCache: CachedFeed? = nil) {
        self.feedCache = feedCache
    }
}

extension InMemoryFeedStore: FeedStore {
    func deleteCachedFeed() throws {
        feedCache = nil
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date) throws {
        feedCache = CachedFeed(feed: feed, timestamp: timestamp)
    }
    
    func retrieve() throws -> CachedFeed? {
        return feedCache
    }
}

extension InMemoryFeedStore: FeedImageDataStore {
    func retrieveData(for url: URL) throws -> Data? {
        return feedImageDataCache[url]
    }
    
    func insert(_ data: Data, for url: URL) throws {
        feedImageDataCache[url] = data
    }
}

extension InMemoryFeedStore {
    static var empty: InMemoryFeedStore { InMemoryFeedStore() }
    
    static var withExpiredFeedCache: InMemoryFeedStore {
        return InMemoryFeedStore(feedCache: CachedFeed(feed: [], timestamp: Date.distantPast))
    }
    
    static var withNonExpiredFeedCache: InMemoryFeedStore {
        return InMemoryFeedStore(feedCache: CachedFeed(feed: [], timestamp: Date()))
    }
}
