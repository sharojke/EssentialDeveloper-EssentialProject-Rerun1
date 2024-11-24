import CoreData
import EssentialFeed
import XCTest

final class CoreDataFeedStoreTests: XCTestCase, FailableFeedStoreSpecs {
    func test_retrieve_deliversEmptyOnEmptyCache() throws {
        let sut = try makeSUT()
        
        assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() throws {
        let sut = try makeSUT()

        assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() throws {
        let sut = try makeSUT()
        
        assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() throws {
        let sut = try makeSUT()
        
        assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
    }
    
    func test_retrieve_deliversFailureOnRetrievalError() throws {
        let stub = NSManagedObjectContext.alwaysFailingFetchStub()
        stub.startIntercepting()
        
        let sut = try makeSUT()

        assertThatRetrieveDeliversFailureOnRetrievalError(on: sut)
    }
    
    func test_retrieve_hasNoSideEffectsOnFailure() throws {
        let stub = NSManagedObjectContext.alwaysFailingFetchStub()
        stub.startIntercepting()
        
        let sut = try makeSUT()
        
        assertThatRetrieveHasNoSideEffectsOnFailure(on: sut)
    }
    
    func test_insert_deliversNoErrorOnEmptyCache() throws {
        let sut = try makeSUT()
        
        assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
    }
    
    func test_insert_deliversNoErrorOnNonEmptyCache() throws {
        let sut = try makeSUT()

        assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
    }
    
    func test_insert_overridesPreviouslyInsertedCacheValues() throws {
        let sut = try makeSUT()

        assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
    }
    
    func test_insert_deliversErrorOnInsertionError() throws {
        let stub = NSManagedObjectContext.alwaysFailingSaveStub()
        stub.startIntercepting()
        
        let sut = try makeSUT()
        
        assertThatInsertDeliversErrorOnInsertionError(on: sut)
    }
    
    func test_insert_hasNoSideEffectsOnFailure() throws {
        let stub = NSManagedObjectContext.alwaysFailingSaveStub()
        stub.startIntercepting()
        
        let sut = try makeSUT()
        
        assertThatInsertHasNoSideEffectsOnInsertionError(on: sut)
    }
    
    func test_delete_deliversNoErrorOnEmptyCache() throws {
        let sut = try makeSUT()
        
        assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() throws {
        let sut = try makeSUT()

        assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
    }
    
    func test_delete_deliversNoErrorOnNonEmptyCache() throws {
        let sut = try makeSUT()

        assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() throws {
        let sut = try makeSUT()
        
        assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
    }
    
    func test_delete_deliversErrorOnDeletionError() throws {
        let stub = NSManagedObjectContext.alwaysFailingSaveStub()
        let sut = try makeSUT()
        
        expect(
            sut,
            toInsertFeed: uniqueFeed().local,
            withTimestamp: Date(),
            andCompleteWith: .success(Void())
        )
        
        stub.startIntercepting()
                
        assertThatDeleteDeliversErrorOnDeletionError(on: sut)
    }
    
    func test_delete_hasNoSideEffectsOnFailure() throws {
        let stub = NSManagedObjectContext.alwaysFailingSaveStub()
        let sut = try makeSUT()
        let feed = uniqueFeed().local
        let timestamp = Date()
        
        expect(
            sut,
            toInsertFeed: feed,
            withTimestamp: timestamp,
            andCompleteWith: .success(Void())
        )
        
        stub.startIntercepting()
        
        assertThatDeleteHasNoSideEffectsOnDeletionError(
            on: sut,
            storedFeed: CachedFeed(feed: feed, timestamp: timestamp)
        )
    }
    
    func test_delete_removesAllObjects() throws {
        let store = try makeSUT()

        expect(
            store,
            toInsertFeed: uniqueFeed().local,
            withTimestamp: Date(),
            andCompleteWith: .success(Void())
        )
        
        expect(store, toDeleteCacheFeed: .success(Void()))

        let context = try NSPersistentContainer.load(
            name: CoreDataFeedStore.modelName,
            model: XCTUnwrap(CoreDataFeedStore.model),
            url: inMemoryStoreURL()
        ).viewContext

        let existingObjects = try context.allExistingObjects()

        XCTAssertEqual(existingObjects, [], "Found orphaned objects in Core Data")
    }
    
    func test_imageEntity_propertiesAreCorrect() throws {
        let entity = try XCTUnwrap(
            CoreDataFeedStore.model?.entitiesByName["ManagedFeedImage"]
        )

        entity.verify(attribute: "id", hasType: .UUIDAttributeType, isOptional: false)
        entity.verify(attribute: "imageDescription", hasType: .stringAttributeType, isOptional: true)
        entity.verify(attribute: "location", hasType: .stringAttributeType, isOptional: true)
        entity.verify(attribute: "url", hasType: .URIAttributeType, isOptional: false)
    }
    
    // MARK: Helper
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) throws -> FeedStore {
        let sut = try CoreDataFeedStore(storeURL: inMemoryStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func inMemoryStoreURL() -> URL {
        return URL(fileURLWithPath: "/dev/null")
            .appendingPathComponent("\(type(of: self)).store")
    }
}
