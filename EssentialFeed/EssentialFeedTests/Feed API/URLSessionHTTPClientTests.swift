import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping
// swiftlint:disable non_overridable_class_declaration

final class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
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

private final class URLProtocolStub: URLProtocol {
    struct Stub {
        let error: Error?
    }
    
    private static var stubs = [URL: Stub]()
    
    static func stub(url: URL, error: Error? = nil) {
        stubs[url] = Stub(error: error)
    }
    
    static func startInterceptingRequests() {
        URLProtocol.registerClass(Self.self)
    }
    
    static func stopInterceptingRequests() {
        URLProtocol.unregisterClass(Self.self)
        stubs = [:]
    }
    
    // if `true` means we handle this request and it's our responsibility
    // to complete it either with success of failure
    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url else { return false }
        
        return Self.stubs[url] != nil
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let url = request.url,
              let stub = Self.stubs[url] else { return }
        
        if let error = stub.error {
            print("LOL")
            print(error)
            client?.urlProtocol(self, didFailWithError: error)
        }
        
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
}

final class URLSessionHTTPClientTests: XCTestCase {
    func test_getFromURL_failsOnRequestError() {
        URLProtocolStub.startInterceptingRequests()
        
        let url = URL(string: "https://a-url.com")!
        let expectedError = NSError(domain: "", code: .zero)
        URLProtocolStub.stub(url: url, error: expectedError)
        
        let sut = URLSessionHTTPClient()
        
        let exp = expectation(description: "Wait for get completion")
        sut.get(from: url) { result in
            switch result {
            case .failure(let receivedError as NSError):
                XCTAssertEqual(receivedError.code, expectedError.code)
                XCTAssertEqual(receivedError.domain, expectedError.domain)
                
            default:
                XCTFail("Expected \(expectedError), got \(result) instead")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
        
        URLProtocolStub.stopInterceptingRequests()
    }
}

// swiftlint:enable force_unwrapping
// swiftlint:enable non_overridable_class_declaration
