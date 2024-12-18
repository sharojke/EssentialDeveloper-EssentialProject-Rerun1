import CoreData
import Foundation

public final class CoreDataFeedStore {
    public enum ContextQueue {
        case main
        case background
    }
    
    public static let modelName = "FeedStore"
    public static let model = NSManagedObjectModel(name: modelName, in: Bundle(for: CoreDataFeedStore.self))
    
    private let container: NSPersistentContainer
    let context: NSManagedObjectContext
    
    public var contextQueue: ContextQueue {
        return context == container.viewContext ? .main : .background
    }
    
    public init(storeURL: URL, contextQueue: ContextQueue = .background) throws {
        guard let model = Self.model else {
            throw ModelNotFound(modelName: Self.modelName)
        }
        
        container = try NSPersistentContainer.load(
            name: Self.modelName,
            model: model,
            url: storeURL
        )
        context = contextQueue == .main ? container.viewContext : container.newBackgroundContext()
    }
    
    public func perform(_ action: @escaping () -> Void) {
        context.perform(action)
    }
    
    private func cleanUpReferencesToPersistentStores() {
        context.performAndWait {
            let coordinator = self.container.persistentStoreCoordinator
            try? coordinator.persistentStores.forEach(coordinator.remove)
        }
    }
    
    /// Encapsulates the whole `CoreData` stack lifecycle within the `CoreDataStore` instance lifetime
    deinit {
        cleanUpReferencesToPersistentStores()
    }
}

public extension CoreDataFeedStore {
    struct ModelNotFound: Error {
        public let modelName: String
    }
}
