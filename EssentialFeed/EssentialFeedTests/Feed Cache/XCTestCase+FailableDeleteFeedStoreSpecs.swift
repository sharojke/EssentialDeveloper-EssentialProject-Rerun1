import EssentialFeed
import XCTest

extension FailableDeleteFeedStoreSpecs where Self: XCTestCase {
    func assertThatDeleteDeliversErrorOnDeletionError(
        on sut: FeedStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        expect(sut, toDeleteCacheFeed: .failure(anyNSError()), file: file, line: line)
    }
    
    func assertThatDeleteHasNoSideEffectsOnDeletionError(
        on sut: FeedStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        expect(sut, toDeleteCacheFeed: .failure(anyNSError()), file: file, line: line)
        
        expect(sut, toRetrieve: .success(LocalFeed(feed: [], timestamp: Date())), file: file, line: line)
    }
}
