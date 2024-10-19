import EssentialFeed
import XCTest

final class EssentialFeedCacheIntegrationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        
        removeStoreArtifacts()
    }
    
    override func tearDown() {
        super.tearDown()
        
        removeStoreArtifacts()
    }
    
    // MARK: LocalFeedLoader Tests
    
    func test_loadFeed_deliversNoItemsOnEmptyCache() throws {
        let feedLoader = try makeFeedLoader()
        
        expect(feedLoader, toLoad: [])
    }
    
    func test_loadFeed_deliversItemsSavedOnASeparateInstance() throws {
        let feedLoaderToPerformSave = try makeFeedLoader()
        let feedLoaderToPerformLoad = try makeFeedLoader()
        let feed = uniqueFeed().models
        
        save(feed: feed, with: feedLoaderToPerformSave)
        
        expect(feedLoaderToPerformLoad, toLoad: feed)
    }
    
    func test_saveFeed_overridesItemsSavedOnASeparateInstance() throws {
        let feedLoaderToPerformFirstSave = try makeFeedLoader()
        let feedLoaderToPerformLastSave = try makeFeedLoader()
        let feedLoaderToPerformLoad = try makeFeedLoader()
        let firstFeed = uniqueFeed().models
        let lastFeed = uniqueFeed().models
        
        save(feed: firstFeed, with: feedLoaderToPerformFirstSave)
        save(feed: lastFeed, with: feedLoaderToPerformLastSave)
        
        expect(feedLoaderToPerformLoad, toLoad: lastFeed)
    }
    
    func test_validateFeedCache_doesNotDeleteRecentlySavedFeed() throws {
        let feedLoaderToPerformSave = try makeFeedLoader()
        let feedLoaderToPerformValidate = try makeFeedLoader()
        let feed = uniqueFeed().models
        
        save(feed: feed, with: feedLoaderToPerformSave)
        validateCache(with: feedLoaderToPerformValidate)
        
        expect(feedLoaderToPerformSave, toLoad: feed)
    }
    
    func test_validateFeedCache_deletesFeedSavedInADistantPast() throws {
        let feedLoaderToPerformSave = try makeFeedLoader(currentDate: .distantPast)
        let feedLoaderToPerformValidate = try makeFeedLoader(currentDate: Date())
        let feed = uniqueFeed().models
        
        save(feed: feed, with: feedLoaderToPerformSave)
        validateCache(with: feedLoaderToPerformValidate)
        
        expect(feedLoaderToPerformSave, toLoad: [])
    }
    
    // MARK: LocalFeedImageDataLoader Tests
    
    func test_loadImageData_deliversSavedDataOnASeparateInstance() throws {
        let imageLoaderToPerformSave = try makeImageLoader()
        let imageLoaderToPerformLoad = try makeImageLoader()
        let feedLoader = try makeFeedLoader()
        let image = uniqueImage()
        let url = image.url
        let data = anyData()
        
        save(feed: [image], with: feedLoader)
        save(data: data, for: url, with: imageLoaderToPerformSave)
        
        expect(imageLoaderToPerformLoad, toLoad: data, for: url)
    }
    
    func test_saveImageData_overridesSavedImageDataOnASeparateInstance() throws {
        let imageLoaderToPerformFirstSave = try makeImageLoader()
        let imageLoaderToPerformLastSave = try makeImageLoader()
        let imageLoaderToPerformLoad = try makeImageLoader()
        let feedLoader = try makeFeedLoader()
        let image = uniqueImage()
        let url = image.url
        let firstImageData = Data("first".utf8)
        let lastImageData = Data("last".utf8)
        
        save(feed: [image], with: feedLoader)
        save(data: firstImageData, for: url, with: imageLoaderToPerformFirstSave)
        save(data: lastImageData, for: url, with: imageLoaderToPerformLastSave)
        
        expect(imageLoaderToPerformLoad, toLoad: lastImageData, for: url)
    }
    
    // MARK: Helpers
    
    private func makeFeedLoader(
        currentDate: Date = Date(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> LocalFeedLoader {
        let store = try CoreDataFeedStore(storeURL: inMemoryStoreURL())
        let sut = LocalFeedLoader(store: store, currentDate: { currentDate })
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func makeImageLoader(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> LocalFeedImageDataLoader {
        let store = try CoreDataFeedStore(storeURL: inMemoryStoreURL())
        let sut = LocalFeedImageDataLoader(store: store)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func inMemoryStoreURL() -> URL {
        return URL(fileURLWithPath: "/dev/null")
            .appendingPathComponent("\(type(of: self)).store")
    }
    
    private func expect(
        _ loader: LocalFeedLoader,
        toLoad expectedFeed: [FeedImage],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for load")
        loader.load { result in
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
    
    private func save(
        feed: [FeedImage],
        with loader: LocalFeedLoader,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for save")
        loader.save(feed) { result in
            switch result {
            case .success:
                break
                
            case .failure(let error):
                XCTFail("Expect success, got \(error) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    private func validateCache(
        with validator: LocalFeedLoader,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for validate")
        validator.validateCache { result in
            switch result {
            case .success:
                break
                
            case .failure(let error):
                XCTFail("Expected to validate feed successfully, got error: \(error)", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
    }
    
    private func save(
        data: Data,
        for url: URL,
        with loader: LocalFeedImageDataLoader,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for save completion")
        loader.save(data, for: url) { result in
            switch result {
            case .success:
                break
                
            case .failure(let error):
                XCTFail(
                    "Expected to save image data successfully, got error: \(error)",
                    file: file,
                    line: line
                )
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
    }
    
    private func expect(
        _ loader: LocalFeedImageDataLoader,
        toLoad expectedData: Data,
        for url: URL,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for load")
        _ = loader.loadImageData(from: url) { result in
            switch result {
            case .success(let receivedData):
                XCTAssertEqual(receivedData, expectedData, file: file, line: line)
                
            case let .failure(error):
                XCTFail("Expected successful image data result, got \(error) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
    }
    
    private func testSpecificStoreURL() -> URL {
        return cachesDirectory().appendingPathComponent("\(type(of: self)).store")
    }
    
    private func cachesDirectory() -> URL {
        // swiftlint:disable:next force_unwrapping
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    private func removeStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
}
