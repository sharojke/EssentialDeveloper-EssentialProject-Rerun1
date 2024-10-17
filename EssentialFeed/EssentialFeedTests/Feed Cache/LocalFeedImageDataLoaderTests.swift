import EssentialFeed
import XCTest

private final class StoreSpy: FeedImageDataStore {
    enum Message: Equatable {
        case retrieveData(for: URL)
    }
    
    private(set) var receivedMessages = [Message]()
    private var completions = [RetrieveCompletion]()
    
    func retrieveData(for url: URL, completion: @escaping RetrieveCompletion) {
        receivedMessages.append(.retrieveData(for: url))
        completions.append(completion)
    }
    
    func complete(with error: Error, at index: Int = .zero) {
        completions[index](.failure(error))
    }
    
    func complete(with data: Data?, at index: Int = .zero) {
        completions[index](.success(data))
    }
}

final class LocalFeedImageDataLoaderTests: XCTestCase {
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertTrue(store.receivedMessages.isEmpty)
    }
    
    func test_loadImageDataFromURL_requestsStoredDataForURL() {
        let (sut, store) = makeSUT()
        let url = anyURL()
        
        _ = sut.loadImageData(from: url) { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.retrieveData(for: url)])
    }
    
    func test_loadImageDataFromURL_failsOnStoreError() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWith: failure(.failed)) {
            store.complete(with: anyError())
        }
    }
    
    func test_loadImageDataFromURL_deliversNotFoundErrorOnNotFound() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWith: failure(.notFound)) {
            store.complete(with: nil)
        }
    }
    
    func test_loadImageDataFromURL_deliversStoredDataOnFoundData() {
        let (sut, store) = makeSUT()
        let data = anyData()
        
        expect(sut, toCompleteWith: .success(data)) {
            store.complete(with: data)
        }
    }
    
    func test_loadImageDataFromURL_doesNotDeliverResultAfterCancellingTask() {
        let (sut, store) = makeSUT()
        
        var receivedResults = [LocalFeedImageDataLoader.LoadImageResult]()
        let task = sut.loadImageData(from: anyURL()) { receivedResults.append($0) }
        
        task.cancel()
        store.complete(with: anyError())
        store.complete(with: anyData())
        store.complete(with: nil)
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    func test_loadImageDataFromURL_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let store = StoreSpy()
        var sut: LocalFeedImageDataLoader? = LocalFeedImageDataLoader(store: store)
        
        var receivedResults = [LocalFeedImageDataLoader.LoadImageResult]()
        _ = sut?.loadImageData(from: anyURL()) { receivedResults.append($0) }
        
        sut = nil
        store.complete(with: anyError())
        store.complete(with: anyData())
        store.complete(with: nil)
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    // MARK: Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: LocalFeedImageDataLoader, store: StoreSpy) {
        let store = StoreSpy()
        let sut = LocalFeedImageDataLoader(store: store)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func failure(
        _ error: LocalFeedImageDataLoader.LoadError
    ) -> LocalFeedImageDataLoader.LoadImageResult {
        return .failure(error)
    }
    
    private func expect(
        _ sut: LocalFeedImageDataLoader,
        toCompleteWith expectedResult: FeedImageDataLoader.LoadImageResult,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let url = anyURL()
        
        let exp = expectation(description: "Wait for load image data completion")
        _ = sut.loadImageData(from: url) { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedData), .success(expectedData)):
                XCTAssertEqual(
                    receivedData,
                    expectedData,
                    "Expected \(expectedData), got \(receivedData) instead",
                    file: file,
                    line: line
                )
                
            case let (
                .failure(receivedError as LocalFeedImageDataLoader.LoadError),
                .failure(expectedError as LocalFeedImageDataLoader.LoadError)
            ):
                XCTAssertEqual(
                    receivedError,
                    expectedError,
                    "Expected \(expectedError), got \(receivedError) instead",
                    file: file,
                    line: line
                )
                
            default:
                XCTFail("Expected \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1)
    }
}
