import EssentialFeed
import XCTest

// swiftlint:disable force_try
// swiftlint:disable force_unwrapping

final class CoreDataFeedImageDataStoreTests: XCTestCase {
    func test_retrieveImageData_deliversNotFoundWhenEmpty() {
        let sut = makeSUT()
        
        expect(sut, toCompleteRetrievalWith: notFound(), for: anyURL())
    }
    
    func test_retrieveImageData_deliversNotFoundWhenStoredDataURLDoesNotMatch() {
        let sut = makeSUT()
        let url = URL(string: "http://a-url.com")!
        let nonMatchingURL = URL(string: "http://another-url.com")!

        insert(anyData(), for: url, into: sut)
        
        expect(sut, toCompleteRetrievalWith: notFound(), for: nonMatchingURL)
    }
    
    func test_retrieveImageData_deliversFoundDataWhenThereIsAStoredImageDataMatchingURL() {
        let sut = makeSUT()
        let url = URL(string: "http://a-url.com")!
        let data = anyData()
        
        insert(data, for: url, into: sut)
        
        expect(sut, toCompleteRetrievalWith: found(data), for: url)
    }
    
    func test_retrieveImageData_deliversLastInsertedValue() {
        let sut = makeSUT()
        let url = URL(string: "http://a-url.com")!
        let firstStoredData = Data("first".utf8)
        let lastStoredData = Data("last".utf8)
        
        insert(firstStoredData, for: url, into: sut)
        insert(lastStoredData, for: url, into: sut)
        
        expect(sut, toCompleteRetrievalWith: found(lastStoredData), for: url)
    }
    
    func test_sideEffects_runSerially() {
        let sut = makeSUT()
        let url = anyURL()
        
        let op1 = expectation(description: "Operation 1")
        sut.insert([localImage(url: url)], timestamp: Date()) { _ in op1.fulfill() }
        
        let op2 = expectation(description: "Operation 2")
        sut.insert(anyData(), for: url) { _ in op2.fulfill() }

        let op3 = expectation(description: "Operation 3")
        sut.insert(anyData(), for: url) { _ in op3.fulfill() }
        
        wait(for: [op1, op2, op3], timeout: 5.0, enforceOrder: true)
    }
    
    // MARK: Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> CoreDataFeedStore {
        let storeURL = URL(fileURLWithPath: "/dev/null")
        let sut = try! CoreDataFeedStore(storeURL: storeURL)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func notFound() -> FeedImageDataStore.RetrieveResult {
        return .success(nil)
    }
    
    private func found(_ data: Data) -> FeedImageDataStore.RetrieveResult {
        return .success(data)
    }
    
    private func localImage(url: URL) -> LocalFeedImage {
        return LocalFeedImage(id: UUID(), description: "any", location: "any", url: url)
    }
    
    private func expect(
        _ sut: CoreDataFeedStore,
        toCompleteRetrievalWith expectedResult: FeedImageDataStore.RetrieveResult,
        for url: URL,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for load completion")
        sut.retrieveData(for: url) { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedData), .success(expectedData)):
                XCTAssertEqual(receivedData, expectedData, file: file, line: line)
                
            default:
                XCTFail("Expected \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    private func insert(
        _ data: Data,
        for url: URL,
        into sut: CoreDataFeedStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let image = localImage(url: url)
        let exp = expectation(description: "Wait for insert completion")
        sut.insert([image], timestamp: Date()) { result in
            switch result {
            case .success:
                sut.insert(data, for: url) { result in
                    switch result {
                    case .success:
                        break
                        
                    case .failure(let error):
                        XCTFail("Failed to insert \(data) with error \(error)", file: file, line: line)
                    }
                    exp.fulfill()
                }
                
            case .failure(let error):
                XCTFail("Failed to save \(image) with error \(error)", file: file, line: line)
                exp.fulfill()
            }
        }
        
        wait(for: [exp], timeout: 1)
    }
}

// swiftlint:enable force_try
// swiftlint:enable force_unwrapping
