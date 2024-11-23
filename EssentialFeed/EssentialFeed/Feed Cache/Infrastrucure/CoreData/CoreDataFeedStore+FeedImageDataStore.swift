import Foundation

extension CoreDataFeedStore: FeedImageDataStore {
    public func retrieveData(for url: URL) throws -> Data? {
        return try performSync { context in
            Result { try ManagedFeedImage.data(with: url, in: context) }
        }
    }
    
    public func insert(_ data: Data, for url: URL) throws {
        try performSync { context in
            Result {
                try ManagedFeedImage.first(with: url, in: context)
                    .map { $0.data = data }
                    .map(context.save)
            }
        }
    }
}
