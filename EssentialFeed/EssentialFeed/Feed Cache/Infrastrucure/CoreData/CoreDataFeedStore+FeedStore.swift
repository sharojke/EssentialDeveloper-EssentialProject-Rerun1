import Foundation

extension CoreDataFeedStore: FeedStore {
    public func insert(
        _ feed: [LocalFeedImage],
        timestamp: Date,
        completion: @escaping FeedStore.InsertCompletion
    ) {
        perform { context in
            do {
                let managedCache = try ManagedCache.newUniqueInstance(in: context)
                managedCache.timestamp = timestamp
                managedCache.feed = ManagedFeedImage.images(from: feed, in: context)

                try context.save()
                completion(.success(Void()))
            } catch {
                context.rollback()
                completion(.failure(error))
            }
        }
    }

    public func deleteCachedFeed(completion: @escaping FeedStore.DeleteCompletion) {
        perform { context in
            do {
                try ManagedCache.deleteCache(in: context)
                completion(.success(Void()))
            } catch {
                context.rollback()
                completion(.failure(error))
            }
        }
    }
    
    public func retrieve(completion: @escaping FeedStore.RetrieveCompletion) {
        perform { context in
            completion(
                Result {
                    try ManagedCache.find(in: context).map { cache in
                        return CachedFeed(feed: cache.localFeed, timestamp: cache.timestamp)
                    }
                }
            )
        }
    }
}
