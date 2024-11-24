import Foundation

extension CoreDataFeedStore: FeedStore {
    public func insert(_ feed: [LocalFeedImage], timestamp: Date) throws {
        return try performSync { context in
            do {
                let managedCache = try ManagedCache.newUniqueInstance(in: context)
                managedCache.timestamp = timestamp
                managedCache.feed = ManagedFeedImage.images(from: feed, in: context)

                try context.save()
                return .success(Void())
            } catch {
                context.rollback()
                return .failure(error)
            }
        }
    }

    public func deleteCachedFeed() throws {
        return try performSync { context in
            do {
                try ManagedCache.deleteCache(in: context)
                return .success(Void())
            } catch {
                context.rollback()
                return .failure(error)
            }
        }
    }
    
    public func retrieve() throws -> CachedFeed? {
        return try performSync { context in
            Result {
                try ManagedCache.find(in: context).map { cache in
                    return CachedFeed(feed: cache.localFeed, timestamp: cache.timestamp)
                }
            }
        }
    }
}
