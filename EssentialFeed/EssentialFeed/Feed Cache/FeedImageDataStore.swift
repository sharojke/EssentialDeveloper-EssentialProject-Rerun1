import Foundation

public protocol FeedImageDataStore {
    typealias RetrieveResult = Result<Data?, Error>
    typealias RetrieveCompletion = (RetrieveResult) -> Void

    func retrieveData(for url: URL, completion: @escaping RetrieveCompletion)
}
