import Foundation

public protocol FeedStore {
    typealias DeleteResult = Result<Void, Error>
    typealias InsertResult = Result<Void, Error>
    
    func deleteCachedFeed(completion: @escaping (DeleteResult) -> Void)
    func insert(_ items: [LocalFeedItem], timestamp: Date, completion: @escaping (InsertResult) -> Void)
}
