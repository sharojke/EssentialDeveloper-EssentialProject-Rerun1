import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping

private final class HTTPClientSpy: HTTPClient {
    private var messages = [(url: URL, completion: (Result<(Data, HTTPURLResponse), Error>) -> Void)]()
    
    var requestedURLs: [URL] {
        return messages.map { $0.url }
    }
    
    func get(from url: URL, completion: @escaping (GetResult) -> Void) {
        messages.append((url, completion))
    }
    
    func complete(with error: Error, at index: Int = 0) {
        messages[index].completion(.failure(error))
    }
    
    func complete(with statusCode: Int, data: Data, at index: Int = 0) {
        let message = messages[index]
        let response = HTTPURLResponse(
            url: message.url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        message.completion(.success((data, response)))
    }
}

final class RemoteFeedImageDataLoader {
    private let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }
    
    func loadImageData(
        from url: URL,
        completion: @escaping FeedImageDataLoader.LoadImageResultCompletion
    ) {
        client.get(from: url) { result in
            switch result {
            case let .success((data, response)):
                break
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

final class RemoteFeedImageDataLoaderTests: XCTestCase {
    func test_init_doesNotPerformAnyURLRequest() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_loadImageDataFromURL_requestsDataFromURL() {
        let (sut, client) = makeSUT()
        let url = anyURL()
        
        sut.loadImageData(from: url) { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadImageDataFromURLTwice_requestsDataFromURLTwice() {
        let (sut, client) = makeSUT()
        let url = anyURL()
        
        sut.loadImageData(from: url) { _ in }
        sut.loadImageData(from: url) { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_loadImageDataFromURL_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        let url = anyURL()
        
        let exp = expectation(description: "Wait for client completion")
        var receivedResult: FeedImageDataLoader.LoadImageResult?
        sut.loadImageData(from: url) { result in
            receivedResult = result
            exp.fulfill()
        }
        
        client.complete(with: anyNSError())
        wait(for: [exp], timeout: 1)
        
        switch receivedResult {
        case .failure:
            break
            
        default:
            XCTFail("Expected failure, got \(receivedResult as Any) instead")
        }
    }
    
    // MARK: Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: RemoteFeedImageDataLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedImageDataLoader(client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }
}

// swiftlint:enable force_unwrapping
