import CoreData
import Foundation

public final class CoreDataFeedStore: FeedStore {
    public static let modelName = "FeedStore"
    public static let model = NSManagedObjectModel(name: modelName, in: Bundle(for: CoreDataFeedStore.self))
    
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    public init(storeURL: URL) throws {
        guard let model = Self.model else {
            throw ModelNotFound(modelName: Self.modelName)
        }

        container = try NSPersistentContainer.load(
            name: Self.modelName,
            model: model,
            url: storeURL
        )
        context = container.newBackgroundContext()
    }

    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertCompletion) {
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

    public func deleteCachedFeed(completion: @escaping DeleteCompletion) {
        perform { context in
            do {
                try ManagedCache.find(in: context)
                    .map(context.delete)
                    .map(context.save)
                completion(.success(Void()))
            } catch {
                context.rollback()
                completion(.failure(error))
            }
        }
    }
    
    public func retrieve(completion: @escaping RetrieveCompletion) {
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

    private func perform(_ action: @escaping (NSManagedObjectContext) -> Void) {
        context.perform { [context] in
            action(context)
        }
    }
    
    private func cleanUpReferencesToPersistentStores() {
        context.performAndWait {
            let coordinator = self.container.persistentStoreCoordinator
            try? coordinator.persistentStores.forEach(coordinator.remove)
        }
    }
    
    deinit {
        cleanUpReferencesToPersistentStores()
    }
}

public extension CoreDataFeedStore {
    struct ModelNotFound: Error {
        public let modelName: String
    }
}
