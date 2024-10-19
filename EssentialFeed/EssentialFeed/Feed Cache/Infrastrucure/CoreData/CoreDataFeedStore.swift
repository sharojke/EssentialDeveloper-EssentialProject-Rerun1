import CoreData
import Foundation

public final class CoreDataFeedStore {
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

    func perform(_ action: @escaping (NSManagedObjectContext) -> Void) {
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
