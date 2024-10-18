import EssentialFeed
import XCTest

// swiftlint:disable force_try

final class CoreDataFeedImageDataStoreTests: XCTestCase {
    func test_retrieveImageData_deliversNotFoundWhenEmpty() {
        let sut = makeSUT()
        
        expect(sut, toCompleteRetrievalWith: notFound(), for: anyURL())
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
            case let (.success( receivedData), .success(expectedData)):
                XCTAssertEqual(receivedData, expectedData, file: file, line: line)
                
            default:
                XCTFail("Expected \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
}

extension CoreDataFeedStore: @retroactive FeedImageDataStore {
    public func retrieveData(for url: URL, completion: @escaping FeedImageDataStore.RetrieveCompletion) {
        completion(.success(nil))
    }
    
    public func insert(_ data: Data, for url: URL, completion: @escaping InsertCompletion) {
    }
}

// swiftlint:enable force_try
