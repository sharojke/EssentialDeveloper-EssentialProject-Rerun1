import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping

final class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    func get(from url: URL, completion: @escaping (HTTPClient.GetResult) -> Void) {
        session.dataTask(with: url) { _, _, error in
            if let error {
                completion(.failure(error))
            }
        }
        .resume()
    }
}

private final class URLSessionSpy: URLSession {
    struct Stub {
        let task: URLSessionDataTask
        let error: Error?
    }
    
    private var stubs = [URL: Stub]()
    
    override func dataTask(
        with url: URL,
        completionHandler: @escaping (Data?, URLResponse?, (any Error)?) -> Void
    ) -> URLSessionDataTask {
        guard let stub = stubs[url] else {
            fatalError("Can not find a stub for \(url)")
        }
        
        completionHandler(nil, nil, stub.error)
        return stub.task
    }
    
    func stub(
        url: URL,
        task: URLSessionDataTask = FakeURLSessionDataTask(),
        error: Error? = nil
    ) {
        stubs[url] = Stub(task: task, error: error)
    }
}

private final class FakeURLSessionDataTask: URLSessionDataTask {
    override func resume() {}
}

private final class URLSessionDataTaskSpy: URLSessionDataTask {
    var resumeCallCount = 0
    
    override func resume() {
        resumeCallCount += 1
    }
}

final class URLSessionHTTPClientTests: XCTestCase {
    func test_getFromURL_resumesDataTaskWithURL() {
        let url = URL(string: "https://a-url.com")!
        let session = URLSessionSpy()
        let task = URLSessionDataTaskSpy()
        let sut = URLSessionHTTPClient(session: session)
        session.stub(url: url, task: task)
        
        sut.get(from: url) { _ in }
        
        XCTAssertEqual(task.resumeCallCount, 1)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let url = URL(string: "https://a-url.com")!
        let session = URLSessionSpy()
        let expectedError = NSError(domain: "", code: .zero)
        let sut = URLSessionHTTPClient(session: session)
        session.stub(url: url, error: expectedError)
        
        let exp = expectation(description: "Wait for get completion")
        sut.get(from: url) { result in
            switch result {
            case .failure(let receivedError as NSError):
                XCTAssertEqual(receivedError, expectedError)
                
            default:
                XCTFail("Expected \(expectedError), got \(result) instead")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
    }
}

// swiftlint:enable force_unwrapping
