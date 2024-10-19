import Foundation

public protocol FeedImageDataCache {
    typealias SaveResult = Result<Void, Error>
    typealias SaveCompletion = (SaveResult) -> Void

    func save(_ data: Data, for url: URL, completion: @escaping SaveCompletion)
}
