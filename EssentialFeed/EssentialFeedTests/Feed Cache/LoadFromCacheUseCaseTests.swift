import EssentialFeed
import XCTest

final class LoadFromCacheUseCaseTests: XCTestCase {
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertTrue(store.receivedMessages.isEmpty)
    }
    
    func test_load_requestsCacheRetrieval() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in }
        
        XCTAssertTrue(store.receivedMessages == [.retrieve])
    }
    
    func test_load_failsOnRetrievalError() {
        let (sut, store) = makeSUT()
        let exptectedError = anyNSError()
        let exp = expectation(description: "Wait for load completion")
        
        var receivedResult: FeedStore.RetrieveResult?
        sut.load { result in
            receivedResult = result
            exp.fulfill()
        }
        store.completeRetrieval(with: exptectedError)
        
        wait(for: [exp], timeout: 1)
        switch receivedResult {
        case .failure(let receivedError as NSError):
            XCTAssertEqual(receivedError.code, exptectedError.code)
            XCTAssertEqual(receivedError.domain, exptectedError.domain)
            
        default:
            XCTFail("Expected failure, received \(receivedResult as Any) instead")
        }
        
        XCTAssertTrue(store.receivedMessages == [.retrieve])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        currentDate: @escaping () -> Date = Date.init,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
}
