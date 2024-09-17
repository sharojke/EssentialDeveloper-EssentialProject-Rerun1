import EssentialFeed
import XCTest

final class ValidateFeedCacheUseCaseTests: XCTestCase {
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertTrue(store.receivedMessages.isEmpty)
    }
    
    func test_validateCache_deletesCacheOnRetrievalError() {
        let (sut, store) = makeSUT()
        
        sut.validateCache()
        store.completeRetrieval(with: anyNSError())
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }
    
    func test_validateCache_doesNotDeleteCacheOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        sut.validateCache()
        store.completeRetrievalWithEmptyCache()
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_validateCache_doesNotDeleteCacheOnLessThanSevenDaysOldCache() {
        let (_, localFeed) = uniqueFeed()
        let (sut, store) = makeSUT()
        let lessThanSevenDaysOld = Date()
            .adding(days: -7, calendar: calendar)
            .adding(seconds: 1, calendar: calendar)
        
        sut.validateCache()
        store.completeRetrieval(with: localFeed, date: lessThanSevenDaysOld)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_validateCache_deletesCacheOnSevenDaysOldCache() {
        let (_, localFeed) = uniqueFeed()
        let (sut, store) = makeSUT()
        let sevenDaysOld = Date()
            .adding(days: -7, calendar: calendar)
        
        sut.validateCache()
        store.completeRetrieval(with: localFeed, date: sevenDaysOld)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }
    
    func test_validateCache_deletesCacheOnMoreThanSevenDaysOldCache() {
        let (_, localFeed) = uniqueFeed()
        let (sut, store) = makeSUT()
        let moreThanSevenDaysOld = Date()
            .adding(days: -7, calendar: calendar)
            .adding(seconds: -1, calendar: calendar)
        
        sut.validateCache()
        store.completeRetrieval(with: localFeed, date: moreThanSevenDaysOld)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }
    
    func test_validateCache_doesNotDeliverResultAfterSUTHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        sut?.validateCache()
        
        sut = nil
        store.completeRetrievalWithEmptyCache()
        
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
}
