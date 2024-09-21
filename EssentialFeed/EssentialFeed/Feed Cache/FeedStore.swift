import Foundation

public protocol FeedStore {
    typealias DeleteResult = Result<Void, Error>
    typealias InsertResult = Result<Void, Error>
    typealias RetrieveResult = Result<LocalFeed, Error>
    
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    func deleteCachedFeed(completion: @escaping (DeleteResult) -> Void)
    
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping (InsertResult) -> Void)
    
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    func retrieve(completion: @escaping (RetrieveResult) -> Void)
}
