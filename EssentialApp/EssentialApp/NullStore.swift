import EssentialFeed
import Foundation

final class NullStore {}

extension NullStore: FeedStore {
    func deleteCachedFeed(completion: @escaping DeleteCompletion) {
        completion(.success(Void()))
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertCompletion) {
        completion(.success(Void()))
    }
    
    func retrieve(completion: @escaping FeedStore.RetrieveCompletion) {
        completion(.success(nil))
    }
}

extension NullStore: FeedImageDataStore {
    func insert(_ data: Data, for url: URL, completion: @escaping InsertCompletion) {
        completion(.success(Void()))
    }
    
    func retrieveData(for url: URL, completion: @escaping FeedImageDataStore.RetrieveCompletion) {
        completion(.success(nil))
    }
}
