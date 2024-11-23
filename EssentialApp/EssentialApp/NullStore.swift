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
    func insert(_ data: Data, for url: URL) throws {}
    
    func retrieveData(for url: URL) throws -> Data? {
        return nil
    }
}
