import EssentialFeed
import Foundation

final class FeedStoreSpy: FeedStore {
    enum Message: Equatable {
        case deleteCachedFeed
        case insert([LocalFeedImage], Date)
        case retrieve
    }
    
    private(set) var receivedMessages = [Message]()
    private var deletionCompletions = [(DeleteResult) -> Void]()
    private var insertionCompletions = [(InsertResult) -> Void]()
    private var retrievalCompletions = [(RetrieveResult) -> Void]()
    
    func deleteCachedFeed(completion: @escaping (DeleteResult) -> Void) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCachedFeed)
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping (InsertResult) -> Void) {
        insertionCompletions.append(completion)
        receivedMessages.append(.insert(feed, timestamp))
    }
    
    func retrieve(completion: @escaping (RetrieveResult) -> Void) {
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
}
