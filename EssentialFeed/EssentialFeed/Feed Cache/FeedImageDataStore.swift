import Foundation

public protocol FeedImageDataStore {
    typealias RetrieveResult = Result<Data?, Error>
    typealias RetrieveCompletion = (RetrieveResult) -> Void
    
    typealias InsertResult = Result<Void, Error>
    typealias InsertCompletion = (InsertResult) -> Void
    
    func retrieveData(for url: URL) throws -> Data?
    func insert(_ data: Data, for url: URL) throws

    @available(*, deprecated)
    func retrieveData(for url: URL, completion: @escaping RetrieveCompletion)
    
    @available(*, deprecated)
    func insert(_ data: Data, for url: URL, completion: @escaping InsertCompletion)
}

public extension FeedImageDataStore {
    func retrieveData(for url: URL) throws -> Data? {
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        var receivedResult: RetrieveResult?
        retrieveData(for: url) { result in
            receivedResult = result
            dispatchGroup.leave()
        }
        
        dispatchGroup.wait()
        return try receivedResult?.get()
    }
    
    func insert(_ data: Data, for url: URL) throws {
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        var receivedResult: InsertResult?
        insert(data, for: url) { result in
            receivedResult = result
            dispatchGroup.leave()
        }
        
        dispatchGroup.wait()
        try receivedResult?.get()
    }
    
    func retrieveData(for url: URL, completion: @escaping RetrieveCompletion) {}
    func insert(_ data: Data, for url: URL, completion: @escaping InsertCompletion) {}
}
