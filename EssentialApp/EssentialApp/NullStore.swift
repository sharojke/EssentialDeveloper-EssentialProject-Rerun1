import EssentialFeed
import Foundation

final class NullStore {}

extension NullStore: FeedStore {
    func deleteCachedFeed() throws {}
    func insert(_ feed: [LocalFeedImage], timestamp: Date) throws {}
    
    func retrieve() throws -> CachedFeed? {
        return nil
    }
}

extension NullStore: FeedImageDataStore {
    func insert(_ data: Data, for url: URL) throws {}
    
    func retrieveData(for url: URL) throws -> Data? {
        return nil
    }
}
