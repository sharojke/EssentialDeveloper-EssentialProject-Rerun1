import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping
// swiftlint:disable force_try

final class EssentialFeedCacheIntegrationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        
        removeStoreArtifacts()
    }
    
    override func tearDown() {
        super.tearDown()
        
        removeStoreArtifacts()
    }
    
    func test_load_deliversNoItemsOnEmptyCache() {
        let sut = makeSUT()
        
        expect(sut, toLoad: [])
    }
    
    func test_load_deliversItemsSavedOnASeparateInstance() {
        let sutToPerformSave = makeSUT()
        let sutToPerformLoad = makeSUT()
        let feed = uniqueFeed().models
        
        let exp1 = expectation(description: "Wait for save")
        sutToPerformSave.save(feed) { result in
            switch result {
            case .success:
                break
                
            case .failure(let error):
                XCTFail("Expect success, got \(error) instead")
            }
            
            exp1.fulfill()
        }
        wait(for: [exp1], timeout: 1)
        
        expect(sutToPerformLoad, toLoad: feed)
    }
    
    func test_save_overridesItemsSavedOnASeparateInstance() {
        let sutToPerformFirstSave = makeSUT()
        let sutToPerformLastSave = makeSUT()
        let sutToPerformLoad = makeSUT()
        let firstFeed = uniqueFeed().models
        let lastFeed = uniqueFeed().models
        
        let exp1 = expectation(description: "Wait for first save")
        sutToPerformFirstSave.save(firstFeed) { result in
            switch result {
            case .success:
                break
                
            case .failure(let error):
                XCTFail("Expect success, got \(error) instead")
            }
            
            exp1.fulfill()
        }
        wait(for: [exp1], timeout: 1)
        
        let exp2 = expectation(description: "Wait for last save")
        sutToPerformLastSave.save(lastFeed) { result in
            switch result {
            case .success:
                break
                
            case .failure(let error):
                XCTFail("Expect success, got \(error) instead")
            }
            
            exp2.fulfill()
        }
        wait(for: [exp2], timeout: 1)
        
        expect(sutToPerformLoad, toLoad: lastFeed)
    }
    
    // MARK: Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> LocalFeedLoader {
        let storeBundle = Bundle(for: CoreDataFeedStore.self)
        let storeURL = testSpecificStoreURL()
        let store = try! CoreDataFeedStore(storeURL: storeURL, bundle: storeBundle)
        let sut = LocalFeedLoader(store: store, currentDate: Date.init)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func expect(
        _ sut: LocalFeedLoader,
        toLoad expectedFeed: [FeedImage],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for load")
        sut.load { result in
            switch result {
            case .success(let receivedFeed):
                XCTAssertEqual(receivedFeed, expectedFeed, file: file, line: line)
                
            case .failure(let error):
                XCTFail("Expected \(expectedFeed), got \(error) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
    }
    
    private func testSpecificStoreURL() -> URL {
        return cachesDirectory().appendingPathComponent("\(type(of: self)).store")
    }
    
    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    private func removeStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
}

// swiftlint:enable force_unwrapping
// swiftlint:enable force_try
