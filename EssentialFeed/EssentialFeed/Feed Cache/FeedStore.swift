import Foundation

// swiftlint:disable implicitly_unwrapped_optional

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
    
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    @available(*, deprecated)
    func deleteCachedFeed(completion: @escaping DeleteCompletion)
    
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    @available(*, deprecated)
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertCompletion)
    
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    @available(*, deprecated)
    func retrieve(completion: @escaping RetrieveCompletion)
}

public extension FeedStore {
    func deleteCachedFeed() throws {
        let dispatchGroup = DispatchGroup()
        var receivedResult: DeleteResult!
        
        dispatchGroup.enter()
        deleteCachedFeed { result in
            receivedResult = result
            dispatchGroup.leave()
        }
        
        dispatchGroup.wait()
        try receivedResult.get()
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date) throws {
        let dispatchGroup = DispatchGroup()
        var receivedResult: InsertResult!
        
        dispatchGroup.enter()
        insert(feed, timestamp: timestamp) { result in
            receivedResult = result
            dispatchGroup.leave()
        }
        
        dispatchGroup.wait()
        try receivedResult.get()
    }
    
    func retrieve() throws -> CachedFeed? {
        let dispatchGroup = DispatchGroup()
        var receivedResult: RetrieveResult!
        
        dispatchGroup.enter()
        retrieve { result in
            receivedResult = result
            dispatchGroup.leave()
        }
        
        dispatchGroup.wait()
        return try receivedResult.get()
    }
    
    func deleteCachedFeed(completion: @escaping DeleteCompletion) {}
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertCompletion) {}
    func retrieve(completion: @escaping RetrieveCompletion) {}
}

// swiftlint:enable implicitly_unwrapped_optional
