import CoreData
import Foundation

public final class CoreDataFeedStore: FeedStore {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext

    public init(storeURL: URL, bundle: Bundle = .main) throws {
        container = try NSPersistentContainer.load(modelName: "FeedStore", url: storeURL, in: bundle)
        context = container.newBackgroundContext()
    }

    public func insert(
        _ feed: [LocalFeedImage],
        timestamp: Date,
        completion: @escaping (InsertResult) -> Void
    ) {
        perform { context in
            do {
                let managedCache = try ManagedCache.newUniqueInstance(in: context)
                managedCache.timestamp = timestamp
                managedCache.feed = ManagedFeedImage.images(from: feed, in: context)

                try context.save()
                completion(.success(Void()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    public func deleteCachedFeed(completion: @escaping (DeleteResult) -> Void) {
        perform { context in
            do {
                try ManagedCache.find(in: context)
                    .map(context.delete)
                    .map(context.save)
                completion(.success(Void()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func retrieve(completion: @escaping (RetrieveResult) -> Void) {
        perform { context in
            do {
                if let cache = try ManagedCache.find(in: context) {
                    completion(.success(LocalFeed(feed: cache.localFeed, timestamp: cache.timestamp)))
                } else {
                    completion(.success(LocalFeed(feed: [], timestamp: Date()))) // ?
                }
            } catch {
                completion(.failure(error))
            }
        }
    }

    private func perform(_ action: @escaping (NSManagedObjectContext) -> Void) {
        let context = context
        context.perform { action(context) }
    }
}
