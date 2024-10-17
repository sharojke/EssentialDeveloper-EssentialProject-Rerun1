import Foundation

public protocol FeedImageDataStore {
    typealias RetrieveResult = Result<Data?, Error>
    typealias RetrieveCompletion = (RetrieveResult) -> Void
    
    typealias InsertResult = Result<Void, Error>
    typealias InsertCompletion = (InsertResult) -> Void

    func retrieveData(for url: URL, completion: @escaping RetrieveCompletion)
    func insert(_ data: Data, for url: URL, completion: @escaping InsertCompletion)
}
