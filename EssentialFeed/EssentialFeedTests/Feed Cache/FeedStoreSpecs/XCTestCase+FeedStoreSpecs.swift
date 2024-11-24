import EssentialFeed
import XCTest

extension FeedStoreSpecs where Self: XCTestCase {
    func assertThatRetrieveDeliversEmptyOnEmptyCache(
        on sut: FeedStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        expect(sut, toRetrieve: .success(nil), file: file, line: line)
    }
    
    func assertThatRetrieveHasNoSideEffectsOnEmptyCache(
        on sut: FeedStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        expect(sut, toRetrieveTwice: .success(nil), file: file, line: line)
    }
    
    func assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(
        on sut: FeedStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let feed = uniqueFeed().local
        let date = Date()

        insert(feed: feed, timestamp: date, to: sut, file: file, line: line)
        
        expect(sut, toRetrieve: .success(CachedFeed(feed: feed, timestamp: date)), file: file, line: line)
    }
    
    func assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(
        on sut: FeedStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let feed = uniqueFeed().local
        let date = Date()

        insert(feed: feed, timestamp: date, to: sut, file: file, line: line)
        
        expect(sut, toRetrieveTwice: .success(CachedFeed(feed: feed, timestamp: date)), file: file, line: line)
    }
    
    func assertThatInsertDeliversNoErrorOnEmptyCache(
        on sut: FeedStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        insert(feed: uniqueFeed().local, timestamp: Date(), to: sut, file: file, line: line)
    }
    
    func assertThatInsertDeliversNoErrorOnNonEmptyCache(
        on sut: FeedStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        insert(feed: uniqueFeed().local, timestamp: Date(), to: sut, file: file, line: line)
        
        insert(feed: uniqueFeed().local, timestamp: Date(), to: sut, file: file, line: line)
    }
    
    func assertThatInsertOverridesPreviouslyInsertedCacheValues(
        on sut: FeedStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        insert(feed: uniqueFeed().local, timestamp: Date(), to: sut, file: file, line: line)
        
        let latestFeed = uniqueFeed().local
        let latestDate = Date()
        insert(feed: latestFeed, timestamp: latestDate, to: sut, file: file, line: line)
        
        expect(
            sut,
            toRetrieve: .success(CachedFeed(feed: latestFeed, timestamp: latestDate)),
            file: file,
            line: line
        )
    }
    
    func assertThatDeleteDeliversNoErrorOnEmptyCache(
        on sut: FeedStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        expect(sut, toDeleteCacheFeed: .success(Void()), file: file, line: line)
    }
    
    func assertThatDeleteHasNoSideEffectsOnEmptyCache(
        on sut: FeedStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        expect(sut, toDeleteCacheFeed: .success(Void()), file: file, line: line)

        expect(sut, toRetrieveTwice: .success(nil), file: file, line: line)
    }
    
    func assertThatDeleteDeliversNoErrorOnNonEmptyCache(
        on sut: FeedStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        insert(feed: uniqueFeed().local, timestamp: Date(), to: sut, file: file, line: line)
        
        expect(sut, toDeleteCacheFeed: .success(Void()), file: file, line: line)
    }
    
    func assertThatDeleteEmptiesPreviouslyInsertedCache(
        on sut: FeedStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        insert(feed: uniqueFeed().local, timestamp: Date(), to: sut, file: file, line: line)
        expect(sut, toDeleteCacheFeed: .success(Void()), file: file, line: line)
        
        expect(sut, toRetrieveTwice: .success(nil), file: file, line: line)
    }
}

extension FeedStoreSpecs where Self: XCTestCase {
    func expect(
        _ sut: FeedStore,
        toRetrieve expectedResult: FeedStore.RetrieveResult,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let receivedResult = Result { try sut.retrieve() }
        
        switch (receivedResult, expectedResult) {
        case let (.success(.some(receivedFeed)), .success(.some(expectedFeed))):
            XCTAssertEqual(receivedFeed.feed, expectedFeed.feed, file: file, line: line)
            XCTAssertEqual(receivedFeed.timestamp, expectedFeed.timestamp, file: file, line: line)
            
        case (.failure, .failure), (.success, .success):
            break
            
        default:
            XCTFail(
                "Expected \(expectedResult), got \(receivedResult) instead",
                file: file,
                line: line
            )
        }
    }
    
    func expect(
        _ sut: FeedStore,
        toRetrieveTwice expectedResult: FeedStore.RetrieveResult,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }
    
    func expect(
        _ sut: FeedStore,
        toInsertFeed feed: [LocalFeedImage],
        withTimestamp timestamp: Date,
        andCompleteWith expectedResult: FeedStore.InsertResult,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let receivedResult = Result { try sut.insert(feed, timestamp: timestamp) }
        
        switch (receivedResult, expectedResult) {
        case (.success, .success), (.failure, .failure):
            break
            
        default:
            XCTFail(
                "Expected \(expectedResult), got \(receivedResult) instead",
                file: file,
                line: line
            )
        }
    }
    
    func expect(
        _ sut: FeedStore,
        toDeleteCacheFeed expectedResult: FeedStore.DeleteResult,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let receivedResult = Result { try sut.deleteCachedFeed() }
        
        switch (receivedResult, expectedResult) {
        case (.success, .success), (.failure, .failure):
            break
            
        default:
            XCTFail(
                "Expected \(expectedResult), got \(receivedResult) instead",
                file: file,
                line: line
            )
        }
    }
    
    func insert(
        feed: [LocalFeedImage],
        timestamp: Date,
        to sut: FeedStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        expect(
            sut,
            toInsertFeed: feed,
            withTimestamp: timestamp,
            andCompleteWith: .success(Void()),
            file: file,
            line: line
        )
    }
}
