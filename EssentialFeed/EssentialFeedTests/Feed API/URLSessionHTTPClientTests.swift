import XCTest

// swiftlint:disable force_unwrapping

final class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    func get(from url: URL) {
        session.dataTask(with: url) { _, _, _ in
        }
        .resume()
    }
}

private final class URLSessionSpy: URLSession {
    private var stubs = [URL: URLSessionDataTask]()
    
    override func dataTask(
        with url: URL,
        completionHandler: @escaping (Data?, URLResponse?, (any Error)?) -> Void
    ) -> URLSessionDataTask {
        return stubs[url] ?? FakeURLSessionDataTask()
    }
    
    func stub(url: URL, task: URLSessionDataTask) {
        stubs[url] = task
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
        
        sut.get(from: url)
        
        XCTAssertEqual(task.resumeCallCount, 1)
    }
}

// swiftlint:enable force_unwrapping
