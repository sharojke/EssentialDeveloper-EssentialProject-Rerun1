import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping
// swiftlint:disable force_try

private final class HTTPClientSpy: HTTPClient {
    private var messages = [(url: URL, completion: (Result<(Data, HTTPURLResponse), Error>) -> Void)]()
    
    var requestedURLs: [URL] {
        return messages.map { $0.url }
    }
    
    func get(from url: URL, completion: @escaping (Result<(Data, HTTPURLResponse), Error>) -> Void) {
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

final class LoadFeedFromRemoteUseCaseTests: XCTestCase {
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://a-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWithResult: failure(.connectivity)) {
            let error = NSError(domain: "a domain", code: .zero)
            client.complete(with: error)
        }
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        let statusCodes = [199, 201, 300, 400, 500]
        statusCodes.enumerated().forEach { index, statusCode in
            expect(sut, toCompleteWithResult: failure(.invalidData)) {
                let json = makeFeedJSON([])
                client.complete(with: statusCode, data: json, at: index)
            }
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWithResult: failure(.invalidData)) {
            let invalidJSON = Data("invalid json".utf8)
            client.complete(with: 200, data: invalidJSON)
        }
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWithResult: .success([])) {
            let emptyListJSON = makeFeedJSON([])
            client.complete(with: 200, data: emptyListJSON)
        }
    }
    
    func test_load_deliversItemsOn200HTTPResponseWithNoJSONItems() {
        let (sut, client) = makeSUT()
        let item1 = makeItem(
            id: UUID(),
            url: URL(string: "https://1.com")!
        )
        let item2 = makeItem(
            id: UUID(),
            url: URL(string: "https://2.com")!,
            description: "2",
            location: "2"
        )
        let items = [item1, item2]
        
        expect(sut, toCompleteWithResult: .success(items.map { $0.model })) {
            let json = makeFeedJSON(items.map { $0.json })
            client.complete(with: 200, data: json)
        }
    }
    
    func test_load_doesNotDeliverResultAfterSUTHasBeenDeallocated() {
        let url = URL(string: "https://any.com")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)
        
        var receivedResults = [RemoteFeedLoader.LoadResult]()
        sut?.load { receivedResults.append($0) }
        
        sut = nil
        client.complete(with: 200, data: makeFeedJSON([]))
        
        XCTAssertTrue(receivedResults.isEmpty)
    }

    // MARK: - Helpers
    
    private func makeSUT(
        url: URL = URL(string: "https://a-url.com")!,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }
    
    private func expect(
        _ sut: RemoteFeedLoader,
        toCompleteWithResult expectedResult: RemoteFeedLoader.LoadResult,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for load completion")
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
                
            case let (.failure(receivedError as RemoteFeedLoader.LoadError),
                      .failure(expectedError as RemoteFeedLoader.LoadError)):
                XCTAssertEqual(
                    receivedError,
                    expectedError,
                    file: file,
                    line: line
                )
                
            default:
                XCTFail(
                    "Expected result \(expectedResult) got \(receivedResult) instead",
                    file: file,
                    line: line
                )
            }
            
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private func makeItem(
        id: UUID,
        url: URL,
        description: String? = nil,
        location: String? = nil
    ) -> (model: FeedImage, json: [String: Any]) {
        let model = FeedImage(
            id: id,
            description: description,
            location: location,
            url: url
        )
        let json = [
            "id": model.id.uuidString,
            "description": model.description as Any,
            "location": model.location as Any,
            "image": model.url.absoluteString
        ].compactMapValues { $0 }
        return (model, json)
    }
    
    private func makeFeedJSON(_ items: [[String: Any]]) -> Data {
        let json = ["items": items]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func failure(_ error: RemoteFeedLoader.LoadError) -> RemoteFeedLoader.LoadResult {
        return .failure(error)
    }
}

// swiftlint:enable force_unwrapping
// swiftlint:enable force_try
