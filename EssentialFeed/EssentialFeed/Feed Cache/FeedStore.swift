import Foundation

public protocol FeedStore {
    typealias DeleteResult = Result<Void, Error>
    typealias InsertResult = Result<Void, Error>
    typealias RetrieveResult = Result<LocalFeed, Error>
    
    func deleteCachedFeed(completion: @escaping (DeleteResult) -> Void)
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping (InsertResult) -> Void)
    func retrieve(completion: @escaping (RetrieveResult) -> Void)
}
