import EssentialFeed
import Foundation

final class FeedImageDataStoreSpy: FeedImageDataStore {
    enum Message: Equatable {
        case retrieveData(for: URL)
        case insert(Data, for: URL)
    }
    
    private(set) var receivedMessages = [Message]()
    private var retrieveCompletions = [RetrieveCompletion]()
    private var insertResult: InsertResult?
    
    // MARK: Retrieve
    
    func retrieveData(for url: URL, completion: @escaping RetrieveCompletion) {
        receivedMessages.append(.retrieveData(for: url))
        retrieveCompletions.append(completion)
    }
    
    func completeRetrieval(with error: Error, at index: Int = .zero) {
        retrieveCompletions[index](.failure(error))
    }
    
    func completeRetrieval(with data: Data?, at index: Int = .zero) {
        retrieveCompletions[index](.success(data))
    }
    
    // MARK: Insertion
    
    func insert(_ data: Data, for url: URL) throws {
        receivedMessages.append(.insert(data, for: url))
        try insertResult?.get()
    }
    
    func completeInsertion(with error: Error, at index: Int = .zero) {
        insertResult = .failure(error)
    }
    
    func completeInsertionSuccessfully(at index: Int = .zero) {
        insertResult = .success(Void())
    }
}
