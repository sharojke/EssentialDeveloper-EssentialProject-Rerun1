import EssentialFeed
import Foundation

final class FeedImageDataStoreSpy: FeedImageDataStore {
    enum Message: Equatable {
        case retrieveData(for: URL)
        case insert(Data, for: URL)
    }
    
    private(set) var receivedMessages = [Message]()
    private var retrieveCompletions = [RetrieveCompletion]()
    private var insertCompletions = [InsertCompletion]()
    
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
    
    func insert(_ data: Data, for url: URL, completion: @escaping InsertCompletion) {
        receivedMessages.append(.insert(data, for: url))
        insertCompletions.append(completion)
    }
    
    func completeInsertion(with error: Error, at index: Int = .zero) {
        insertCompletions[index](.failure(error))
    }
    
    func completeInsertionSuccessfully(at index: Int = .zero) {
        insertCompletions[index](.success(Void()))
    }
}
