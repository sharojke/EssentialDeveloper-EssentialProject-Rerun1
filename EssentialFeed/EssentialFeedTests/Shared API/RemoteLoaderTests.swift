import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping
// swiftlint:disable force_try

final class RemoteLoaderTests: XCTestCase {
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
    
    func test_load_deliversErrorOnMapperError() {
        let (sut, client) = makeSUT { _, _ in
            throw anyError()
        }
        
        expect(sut, toCompleteWithResult: failure(.invalidData)) {
            client.complete(with: 200, data: anyData())
        }
    }
    
    func test_load_deliversMappedResource() {
        let resource = "resource"
        let (sut, client) = makeSUT { data, _ in
            return String(data: data, encoding: .utf8)!
        }
        
        expect(sut, toCompleteWithResult: .success(resource)) {
            client.complete(with: 200, data: Data(resource.utf8))
        }
    }
    
    func test_load_doesNotDeliverResultAfterSUTHasBeenDeallocated() {
        let url = URL(string: "https://any.com")!
        let client = HTTPClientSpy()
        var sut: RemoteLoader? = RemoteLoader<String>(url: url, client: client) { _, _ in "any" }
        
        var receivedResults = [RemoteLoader<String>.LoadResult]()
        sut?.load { receivedResults.append($0) }
        
        sut = nil
        client.complete(with: 200, data: makeFeedJSON([]))
        
        XCTAssertTrue(receivedResults.isEmpty)
    }

    // MARK: - Helpers
    
    private func makeSUT(
        url: URL = URL(string: "https://a-url.com")!,
        mapper: @escaping RemoteLoader<String>.Mapper = { _, _ in "any" },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: RemoteLoader<String>, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteLoader(url: url, client: client, mapper: mapper)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }
    
    private func expect(
        _ sut: RemoteLoader<String>,
        toCompleteWithResult expectedResult: RemoteLoader<String>.LoadResult,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for load completion")
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
                
            case let (.failure(receivedError as RemoteLoader<String>.LoadError),
                      .failure(expectedError as RemoteLoader<String>.LoadError)):
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
    
    private func failure(_ error: RemoteLoader<String>.LoadError) -> RemoteLoader<String>.LoadResult {
        return .failure(error)
    }
}

// swiftlint:enable force_unwrapping
// swiftlint:enable force_try
