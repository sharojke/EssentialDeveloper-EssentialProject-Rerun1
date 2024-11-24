import Foundation

public typealias CachedFeed = (feed: [LocalFeedImage], timestamp: Date)

public protocol FeedStore {
    typealias DeleteResult = Result<Void, Error>
    typealias DeleteCompletion = (DeleteResult) -> Void
    
    typealias InsertResult = Result<Void, Error>
    typealias InsertCompletion = (InsertResult) -> Void
    
    typealias RetrieveResult = Result<CachedFeed?, Error>
    typealias RetrieveCompletion = (RetrieveResult) -> Void
    
    func deleteCachedFeed() throws
    func insert(_ feed: [LocalFeedImage], timestamp: Date) throws
    func retrieve() throws -> CachedFeed?
}
