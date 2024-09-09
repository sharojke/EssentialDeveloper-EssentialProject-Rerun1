import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping
// swiftlint:disable non_overridable_class_declaration

final class URLSessionHTTPClient {
    private struct UnexpectedValuesRepresentation: Error {}
    
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func get(from url: URL, completion: @escaping (HTTPClient.GetResult) -> Void) {
        session.dataTask(with: url) { _, _, error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }
        .resume()
    }
}

private final class URLProtocolStub: URLProtocol {
    struct Stub {
        let data: Data?
        let response: URLResponse?
        let error: Error?
    }
    
    private static var stub: Stub?
    private static var requestObserver: ((URLRequest) -> Void)?
    
    static func stub(data: Data?, response: URLResponse?, error: Error?) {
        stub = Stub(data: data, response: response, error: error)
    }
    
    static func observeRequests(observer: @escaping (URLRequest) -> Void) {
        requestObserver = observer
    }
    
    static func startInterceptingRequests() {
        URLProtocol.registerClass(Self.self)
    }
    
    static func stopInterceptingRequests() {
        URLProtocol.unregisterClass(Self.self)
        stub = nil
        requestObserver = nil
    }
    
    // if `true` means we handle this request and it's our responsibility
    // to complete it either with success of failure
    override class func canInit(with request: URLRequest) -> Bool {
        requestObserver?(request)
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        if let data = Self.stub?.data {
            client?.urlProtocol(self, didLoad: data)
        }
        
        if let response = Self.stub?.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        
        if let error = Self.stub?.error {
            client?.urlProtocol(self, didFailWithError: error)
        }
        
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
}

final class URLSessionHTTPClientTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        
        URLProtocolStub.startInterceptingRequests()
    }
    
    override class func tearDown() {
        super.tearDown()
        
        URLProtocolStub.stopInterceptingRequests()
    }
    
    func test_getFromURL_performsGETRequestWithURL() {
        let url = anyURL()
        
        let exp = expectation(description: "Wait for request")
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        makeSUT().get(from: url) { _ in }
        
        wait(for: [exp], timeout: 1)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let expectedError = NSError(domain: "", code: .zero)
        let receivedError = resultError(data: nil, response: nil, error: expectedError) as? NSError
        
        XCTAssertEqual(receivedError?.code, expectedError.code)
        XCTAssertEqual(receivedError?.domain, expectedError.domain)
    }
    
    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        XCTAssertNotNil(resultError(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultError(data: nil, response: nonHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultError(data: nil, response: anyHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultError(data: anyData(), response: nil, error: nil))
        XCTAssertNotNil(resultError(data: anyData(), response: nil, error: anyError()))
        XCTAssertNotNil(resultError(data: nil, response: nonHTTPURLResponse(), error: anyError()))
        XCTAssertNotNil(resultError(data: nil, response: anyHTTPURLResponse(), error: anyError()))
        XCTAssertNotNil(resultError(data: anyData(), response: nonHTTPURLResponse(), error: anyError()))
        XCTAssertNotNil(resultError(data: anyData(), response: anyHTTPURLResponse(), error: anyError()))
        XCTAssertNotNil(resultError(data: anyData(), response: nonHTTPURLResponse(), error: nil))
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func anyURL() -> URL {
        return URL(string: "https://a-url.com")!
    }
    
    private func nonHTTPURLResponse() -> URLResponse {
        return URLResponse(
            url: anyURL(),
            mimeType: nil,
            expectedContentLength: .zero,
            textEncodingName: nil
        )
    }
    
    private func anyHTTPURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(
            url: anyURL(),
            mimeType: nil,
            expectedContentLength: .zero,
            textEncodingName: nil
        )
    }
    
    private func anyData() -> Data {
        return Data()
    }
    
    private func anyError() -> Error {
        return NSError(domain: "", code: .zero)
    }
    
    private func resultError(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Error? {
        URLProtocolStub.stub(data: data, response: response, error: error)
        
        let sut = makeSUT(file: file, line: line)
        
        let exp = expectation(description: "Wait for get completion")
        var receivedError: Error?
        sut.get(from: anyURL()) { result in
            switch result {
            case .failure(let error):
                receivedError = error
                
            default:
                XCTFail("Expected failure, got \(result) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
        return receivedError
    }
}

// swiftlint:enable force_unwrapping
// swiftlint:enable non_overridable_class_declaration
