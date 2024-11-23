import Foundation

public protocol FeedImageDataStore {
    func retrieveData(for url: URL) throws -> Data?
    func insert(_ data: Data, for url: URL) throws
}
