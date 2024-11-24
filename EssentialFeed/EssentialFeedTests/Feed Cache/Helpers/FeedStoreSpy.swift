import EssentialFeed
import Foundation

final class FeedStoreSpy: FeedStore {
    enum Message: Equatable {
        case deleteCachedFeed
        case insert([LocalFeedImage], Date)
        case retrieve
    }
    
    private(set) var receivedMessages = [Message]()
    private var deletionResult: Result<Void, Error>?
    private var insertionResult: Result<Void, Error>?
    private var retrievalResult: Result<CachedFeed?, Error>?
    
    func deleteCachedFeed() throws {
        receivedMessages.append(.deleteCachedFeed)
        try deletionResult?.get()
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date) throws {
        receivedMessages.append(.insert(feed, timestamp))
        try insertionResult?.get()
    }
    
    func retrieve() throws -> CachedFeed? {
        receivedMessages.append(.retrieve)
        return try retrievalResult?.get()
    }
    
    func completeDeletion(with error: Error, at index: Int = .zero) {
        deletionResult = .failure(error)
    }
    
    func completeDeletionSuccessfully(at index: Int = .zero) {
        deletionResult = .success(Void())
    }
    
    func completeInsertion(with error: Error, at index: Int = .zero) {
        insertionResult = .failure(error)
    }
    
    func completeInsertionSuccessfully(at index: Int = .zero) {
        insertionResult = .success(Void())
    }
    
    func completeRetrieval(with error: Error, at index: Int = .zero) {
        retrievalResult = .failure(error)
    }
    
    func completeRetrievalWithEmptyCache(at index: Int = .zero) {
        retrievalResult = .success(CachedFeed(feed: [], timestamp: Date()))
    }
    
    func completeRetrieval(with localFeed: [LocalFeedImage], date: Date, at index: Int = .zero) {
        retrievalResult = .success(CachedFeed(feed: localFeed, timestamp: date))
    }
}
