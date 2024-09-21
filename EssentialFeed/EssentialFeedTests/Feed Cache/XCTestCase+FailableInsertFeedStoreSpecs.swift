import EssentialFeed
import XCTest

extension FailableInsertFeedStoreSpecs where Self: XCTestCase {
    func assertThatInsertDeliversErrorOnInsertionError(
        on sut: FeedStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        expect(
            sut,
            toInsertFeed: uniqueFeed().local,
            withTimestamp: Date(),
            andCompleteWith: .failure(anyNSError()),
            file: file,
            line: line
        )
    }
    
    func assertThatInsertHasNoSideEffectsOnInsertionError(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        expect(
            sut,
            toInsertFeed: uniqueFeed().local,
            withTimestamp: Date(),
            andCompleteWith: .failure(anyNSError()),
            file: file,
            line: line
        )
        
        expect(sut, toRetrieve: .success(LocalFeed(feed: [], timestamp: Date())), file: file, line: line)
    }
}
