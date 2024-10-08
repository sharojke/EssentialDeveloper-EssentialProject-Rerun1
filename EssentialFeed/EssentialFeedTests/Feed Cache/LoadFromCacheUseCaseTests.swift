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
        let expectedError = anyNSError()
        
        expect(sut, toCompleteWith: .failure(expectedError)) {
            store.completeRetrieval(with: expectedError)
        }
    }
    
    func test_load_deliversNoImagesOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrievalWithEmptyCache()
        }
    }
    
    func test_load_deliversTheCacheOnNonExpiredCache() {
        let (feed, localFeed) = uniqueFeed()
        let (sut, store) = makeSUT()
        let nonExpired = Date()
            .minusFeedCacheMaxAge(calendar: calendar)
            .adding(seconds: 1, calendar: calendar)
        
        expect(sut, toCompleteWith: .success(feed)) {
            store.completeRetrieval(with: localFeed, date: nonExpired)
        }
    }
    
    func test_load_deliversNoImagesOnCacheExpiration() {
        let (_, localFeed) = uniqueFeed()
        let (sut, store) = makeSUT()
        let expiration = Date()
            .minusFeedCacheMaxAge(calendar: calendar)
        
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrieval(with: localFeed, date: expiration)
        }
    }
    
    func test_load_deliversNoImagesOnExpiredCache() {
        let (_, localFeed) = uniqueFeed()
        let (sut, store) = makeSUT()
        let moreThanSevenDaysOld = Date()
            .minusFeedCacheMaxAge(calendar: calendar)
            .adding(seconds: -1, calendar: calendar)
        
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrieval(with: localFeed, date: moreThanSevenDaysOld)
        }
    }
    
    func test_load_hasNoSideEffectsOnRetrievalError() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in }
        store.completeRetrieval(with: anyNSError())
        
        XCTAssertTrue(store.receivedMessages == [.retrieve])
    }
    
    func test_load_hasNoSideEffectsOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in }
        store.completeRetrievalWithEmptyCache()
        
        XCTAssertTrue(store.receivedMessages == [.retrieve])
    }
    
    func test_load_hasNoSideEffectsOnNonExpiredCache() {
        let (_, localFeed) = uniqueFeed()
        let (sut, store) = makeSUT()
        let lessThanSevenDaysOld = Date()
            .minusFeedCacheMaxAge(calendar: calendar)
            .adding(seconds: 1, calendar: calendar)
        
        sut.load { _ in }
        store.completeRetrieval(with: localFeed, date: lessThanSevenDaysOld)
        
        XCTAssertTrue(store.receivedMessages == [.retrieve])
    }
    
    func test_load_hasNoSideEffectsOnCacheExpiration() {
        let (_, localFeed) = uniqueFeed()
        let (sut, store) = makeSUT()
        let expiration = Date()
            .minusFeedCacheMaxAge(calendar: calendar)
        
        sut.load { _ in }
        store.completeRetrieval(with: localFeed, date: expiration)
        
        XCTAssertTrue(store.receivedMessages == [.retrieve])
    }
    
    func test_load_hasNoSideEffectsOnExpiredCache() {
        let (_, localFeed) = uniqueFeed()
        let (sut, store) = makeSUT()
        let expired = Date()
            .minusFeedCacheMaxAge(calendar: calendar)
            .adding(seconds: -1, calendar: calendar)
        
        sut.load { _ in }
        store.completeRetrieval(with: localFeed, date: expired)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_doesNotDeliverResultAfterSUTHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: FeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedResults = [FeedLoader.LoadResult]()
        sut?.load { receivedResults.append($0) }
        
        sut = nil
        store.completeRetrievalWithEmptyCache()
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        currentDate: @escaping () -> Date = Date.init,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: FeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func expect(
        _ sut: FeedLoader,
        toCompleteWith expectedResult: FeedLoader.LoadResult,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for load completion")
        
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedFeed), .success(expectedFeed)):
                XCTAssertEqual(
                    receivedFeed,
                    expectedFeed,
                    "Expected \(expectedFeed), got \(receivedFeed) instead",
                    file: file,
                    line: line
                )
                
            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(
                    receivedError.domain,
                    expectedError.domain,
                    "Expected \(receivedError.domain), got \(receivedError.domain) instead",
                    file: file,
                    line: line
                )
                XCTAssertEqual(
                    receivedError.code,
                    receivedError.code,
                    "Expected \(receivedError.code), got \(receivedError.code) instead",
                    file: file,
                    line: line
                )
                
            default:
                XCTFail(
                    "Expected \(expectedResult), received \(receivedResult) instead", file: file, line: line
                )
            }
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1)
    }
}
