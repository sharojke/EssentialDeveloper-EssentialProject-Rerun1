import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping

private final class HTTPClientSpy: HTTPClient {
    var requestedURLs = [URL]()
    var capturedCompletions = [(Error) -> Void]()
    
    func get(from url: URL, completion: @escaping (Error) -> Void) {
        requestedURLs.append(url)
        capturedCompletions.append(completion)
    }
}

final class RemoteFeedLoaderTests: XCTestCase {
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://a-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load()
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load()
        sut.load()
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        
        var receivedErrors = [RemoteFeedLoaderError]()
        sut.load { receivedErrors.append($0) }
        
        let error = NSError(domain: "a domain", code: .zero)
        client.capturedCompletions.first?(error)
        
        XCTAssertEqual(receivedErrors, [.connectivity])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        url: URL = URL(string: "https://a-url.com")!
    ) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
}

// swiftlint:enable force_unwrapping
