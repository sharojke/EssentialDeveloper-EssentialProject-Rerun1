import Foundation

extension CoreDataFeedStore: FeedImageDataStore {
    public func retrieveData(for url: URL, completion: @escaping FeedImageDataStore.RetrieveCompletion) {
        completion(.success(nil))
    }
    
    public func insert(
        _ data: Data,
        for url: URL,
        completion: @escaping FeedImageDataStore.InsertCompletion
    ) {
        completion(.success(Void()))
    }
}
