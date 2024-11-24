import EssentialFeed
import XCTest

final class LoadFromCacheUseCaseTests: XCTestCase {
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertTrue(store.receivedMessages.isEmpty)
    }
    
    func test_load_requestsCacheRetrieval() {
        let (sut, store) = makeSUT()
        
        _ = try? sut.load()
        
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
        store.completeRetrieval(with: anyNSError())
        
        _ = try? sut.load()
        
        XCTAssertTrue(store.receivedMessages == [.retrieve])
    }
    
    func test_load_hasNoSideEffectsOnEmptyCache() {
        let (sut, store) = makeSUT()
        store.completeRetrievalWithEmptyCache()
        
        _ = try? sut.load()
        
        XCTAssertTrue(store.receivedMessages == [.retrieve])
    }
    
    func test_load_hasNoSideEffectsOnNonExpiredCache() {
        let (_, localFeed) = uniqueFeed()
        let (sut, store) = makeSUT()
        let lessThanSevenDaysOld = Date()
            .minusFeedCacheMaxAge(calendar: calendar)
            .adding(seconds: 1, calendar: calendar)
        store.completeRetrieval(with: localFeed, date: lessThanSevenDaysOld)
        
        _ = try? sut.load()
        
        XCTAssertTrue(store.receivedMessages == [.retrieve])
    }
    
    func test_load_hasNoSideEffectsOnCacheExpiration() {
        let (_, localFeed) = uniqueFeed()
        let (sut, store) = makeSUT()
        let expiration = Date()
            .minusFeedCacheMaxAge(calendar: calendar)
        store.completeRetrieval(with: localFeed, date: expiration)
        
        _ = try? sut.load()
        
        XCTAssertTrue(store.receivedMessages == [.retrieve])
    }
    
    func test_load_hasNoSideEffectsOnExpiredCache() {
        let (_, localFeed) = uniqueFeed()
        let (sut, store) = makeSUT()
        let expired = Date()
            .minusFeedCacheMaxAge(calendar: calendar)
            .adding(seconds: -1, calendar: calendar)
        store.completeRetrieval(with: localFeed, date: expired)
        
        _ = try? sut.load()
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
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
    
    private func expect(
        _ sut: LocalFeedLoader,
        toCompleteWith expectedResult: LocalFeedLoader.LoadResult,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        action()
        
        let receivedResult = Result { try sut.load() }
        
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
    }
}
