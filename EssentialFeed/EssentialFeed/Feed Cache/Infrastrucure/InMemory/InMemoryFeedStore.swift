import Foundation

// swiftlint:disable legacy_objc_type

public final class InMemoryFeedStore {
    private(set) var feedCache: CachedFeed?
    private var feedImageDataCache = NSCache<NSURL, NSData>()

    public init() {}
}

extension InMemoryFeedStore: FeedStore {
    public func deleteCachedFeed() throws {
        feedCache = nil
    }
    
    public func insert(_ feed: [LocalFeedImage], timestamp: Date) throws {
        feedCache = CachedFeed(feed: feed, timestamp: timestamp)
    }
    
    public func retrieve() throws -> CachedFeed? {
        return feedCache
    }
}

extension InMemoryFeedStore: FeedImageDataStore {
    public func retrieveData(for url: URL) throws -> Data? {
        return feedImageDataCache.object(forKey: url as NSURL) as Data?
    }
    
    public func insert(_ data: Data, for url: URL) throws {
        feedImageDataCache.setObject(data as NSData, forKey: url as NSURL)
    }
}

// swiftlint:enable legacy_objc_type
