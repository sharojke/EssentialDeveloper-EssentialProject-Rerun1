import Foundation

public struct LocalFeedItem: Equatable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let imageURL: URL
    
    public init(id: UUID, description: String?, location: String?, imageURL: URL) {
        self.id = id
        self.description = description
        self.location = location
        self.imageURL = imageURL
    }
}

public protocol FeedStore {
    typealias DeleteResult = Result<Void, Error>
    typealias InsertResult = Result<Void, Error>
    
    func deleteCachedFeed(completion: @escaping (DeleteResult) -> Void)
    func insert(_ items: [LocalFeedItem], timestamp: Date, completion: @escaping (InsertResult) -> Void)
}
