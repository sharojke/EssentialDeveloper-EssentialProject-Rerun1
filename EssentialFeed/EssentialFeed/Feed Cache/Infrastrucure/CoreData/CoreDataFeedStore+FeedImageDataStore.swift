import Foundation

extension CoreDataFeedStore: FeedImageDataStore {
    public func retrieveData(for url: URL) throws -> Data? {
        return try ManagedFeedImage.data(with: url, in: context)
    }
    
    public func insert(_ data: Data, for url: URL) throws {
        try ManagedFeedImage.first(with: url, in: context)
            .map { $0.data = data }
            .map(context.save)
    }
}
