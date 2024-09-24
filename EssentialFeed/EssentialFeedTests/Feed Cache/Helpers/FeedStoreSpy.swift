import EssentialFeed
import Foundation

final class FeedStoreSpy: FeedStore {
    enum Message: Equatable {
        case deleteCachedFeed
        case insert([LocalFeedImage], Date)
        case retrieve
    }
    
    private(set) var receivedMessages = [Message]()
    private var deletionCompletions = [DeleteCompletion]()
    private var insertionCompletions = [InsertCompletion]()
    private var retrievalCompletions = [RetrieveCompletion]()
    
    func deleteCachedFeed(completion: @escaping DeleteCompletion) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCachedFeed)
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertCompletion) {
        insertionCompletions.append(completion)
        receivedMessages.append(.insert(feed, timestamp))
    }
    
    func retrieve(completion: @escaping RetrieveCompletion) {
        retrievalCompletions.append(completion)
        receivedMessages.append(.retrieve)
    }
    
    func completeDeletion(with error: Error, at index: Int = .zero) {
        deletionCompletions[index](.failure(error))
    }
    
    func completeDeletionSuccessfully(at index: Int = .zero) {
        deletionCompletions[index](.success(Void()))
    }
    
    func completeInsertion(with error: Error, at index: Int = .zero) {
        insertionCompletions[index](.failure(error))
    }
    
    func completeInsertionSuccessfully(at index: Int = .zero) {
        insertionCompletions[index](.success(Void()))
    }
    
    func completeRetrieval(with error: Error, at index: Int = .zero) {
        retrievalCompletions[index](.failure(error))
    }
    
    func completeRetrievalWithEmptyCache(at index: Int = .zero) {
        retrievalCompletions[index](.success(CachedFeed(feed: [], timestamp: Date())))
    }
    
    func completeRetrieval(with localFeed: [LocalFeedImage], date: Date, at index: Int = .zero) {
        retrievalCompletions[index](.success(CachedFeed(feed: localFeed, timestamp: date)))
    }
}
