import Foundation

extension CoreDataFeedStore: FeedStore {
    public func insert(_ feed: [LocalFeedImage], timestamp: Date) throws {
        do {
            let managedCache = try ManagedCache.newUniqueInstance(in: context)
            managedCache.timestamp = timestamp
            managedCache.feed = ManagedFeedImage.images(from: feed, in: context)

            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    public func deleteCachedFeed() throws {
        do {
            try ManagedCache.deleteCache(in: context)
        } catch {
            context.rollback()
            throw error
        }
    }
    
    public func retrieve() throws -> CachedFeed? {
        return try ManagedCache.find(in: context).map { cache in
            return CachedFeed(feed: cache.localFeed, timestamp: cache.timestamp)
        }
    }
}
