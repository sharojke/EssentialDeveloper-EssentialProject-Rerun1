import EssentialFeed
import Foundation

private final class Task: HTTPClientTask {
    func cancel() {}
}

final class HTTPClientStub {
    private let stub: (URL) -> GetResult
    
    init(stub: @escaping (URL) -> GetResult) {
        self.stub = stub
    }
}

extension HTTPClientStub: HTTPClient {
    func get(from url: URL, completion: @escaping (GetResult) -> Void) -> HTTPClientTask {
        completion(stub(url))
        return Task()
    }
}

extension HTTPClientStub {
    static func offline() -> HTTPClientStub {
        return HTTPClientStub { _ in .failure(anyError()) }
    }
    
    static func online(_ stub: @escaping (URL) -> (Data, HTTPURLResponse)) -> HTTPClientStub {
        return HTTPClientStub { .success(stub($0)) }
    }
}
