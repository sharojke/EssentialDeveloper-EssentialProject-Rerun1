import CoreData
import EssentialFeed
import XCTest

final class CoreDataFeedStoreTests: XCTestCase, FailableFeedStoreSpecs {
    func test_retrieve_deliversEmptyOnEmptyCache() throws {
        try makeSUT { sut in
            self.assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
        }
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() throws {
        try makeSUT { sut in
            self.assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
        }
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() throws {
        try makeSUT { sut in
            self.assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
        }
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() throws {
        try makeSUT { sut in
            self.assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
        }
    }
    
    func test_retrieve_deliversFailureOnRetrievalError() throws {
        let stub = NSManagedObjectContext.alwaysFailingFetchStub()
        stub.startIntercepting()
        
        try makeSUT { sut in
            self.assertThatRetrieveDeliversFailureOnRetrievalError(on: sut)
        }
    }
    
    func test_retrieve_hasNoSideEffectsOnFailure() throws {
        let stub = NSManagedObjectContext.alwaysFailingFetchStub()
        stub.startIntercepting()
        
        try makeSUT { sut in
            self.assertThatRetrieveHasNoSideEffectsOnFailure(on: sut)
        }
    }
    
    func test_insert_deliversNoErrorOnEmptyCache() throws {
        try makeSUT { sut in
            self.assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
        }
    }
    
    func test_insert_deliversNoErrorOnNonEmptyCache() throws {
        try makeSUT { sut in
            self.assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
        }
    }
    
    func test_insert_overridesPreviouslyInsertedCacheValues() throws {
        try makeSUT { sut in
            self.assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
        }
    }
    
    func test_insert_deliversErrorOnInsertionError() throws {
        let stub = NSManagedObjectContext.alwaysFailingSaveStub()
        stub.startIntercepting()
        
        try makeSUT { sut in
            self.assertThatInsertDeliversErrorOnInsertionError(on: sut)
        }
    }
    
    func test_insert_hasNoSideEffectsOnFailure() throws {
        let stub = NSManagedObjectContext.alwaysFailingSaveStub()
        stub.startIntercepting()
        
        try makeSUT { sut in
            self.assertThatInsertHasNoSideEffectsOnInsertionError(on: sut)
        }
    }
    
    func test_delete_deliversNoErrorOnEmptyCache() throws {
        try makeSUT { sut in
            self.assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
        }
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() throws {
        try makeSUT { sut in
            self.assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
        }
    }
    
    func test_delete_deliversNoErrorOnNonEmptyCache() throws {
        try makeSUT { sut in
            self.assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)
        }
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() throws {
        try makeSUT { sut in
            self.assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
        }
    }
    
    func test_delete_deliversErrorOnDeletionError() throws {
        let stub = NSManagedObjectContext.alwaysFailingSaveStub()
        
        try makeSUT { sut in
            self.expect(
                sut,
                toInsertFeed: uniqueFeed().local,
                withTimestamp: Date(),
                andCompleteWith: .success(Void())
            )
            
            stub.startIntercepting()
                    
            self.assertThatDeleteDeliversErrorOnDeletionError(on: sut)
        }
    }
    
    func test_delete_hasNoSideEffectsOnFailure() throws {
        let stub = NSManagedObjectContext.alwaysFailingSaveStub()
        let feed = uniqueFeed().local
        let timestamp = Date()
        
        try makeSUT { sut in
            self.expect(
                sut,
                toInsertFeed: feed,
                withTimestamp: timestamp,
                andCompleteWith: .success(Void())
            )
            
            stub.startIntercepting()
            
            self.assertThatDeleteHasNoSideEffectsOnDeletionError(
                on: sut,
                storedFeed: CachedFeed(feed: feed, timestamp: timestamp)
            )
        }
    }
    
    func test_delete_removesAllObjects() throws {
        try makeSUT { store in
            self.expect(
                store,
                toInsertFeed: uniqueFeed().local,
                withTimestamp: Date(),
                andCompleteWith: .success(Void())
            )
            
            self.expect(store, toDeleteCacheFeed: .success(Void()))
            
            let context = try? NSPersistentContainer.load(
                name: CoreDataFeedStore.modelName,
                model: XCTUnwrap(CoreDataFeedStore.model),
                url: self.inMemoryStoreURL()
            ).viewContext
            
            let existingObjects = try? context?.allExistingObjects()
            
            XCTAssertEqual(existingObjects, [], "Found orphaned objects in Core Data")
        }
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
    
    private func makeSUT(
        _ test: @escaping (CoreDataFeedStore) -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let sut = try CoreDataFeedStore(storeURL: inMemoryStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        
        let exp = expectation(description: "wait for operation")
        sut.perform {
            test(sut)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 0.1)
    }
    
    private func inMemoryStoreURL() -> URL {
        return URL(fileURLWithPath: "/dev/null")
            .appendingPathComponent("\(type(of: self)).store")
    }
}
