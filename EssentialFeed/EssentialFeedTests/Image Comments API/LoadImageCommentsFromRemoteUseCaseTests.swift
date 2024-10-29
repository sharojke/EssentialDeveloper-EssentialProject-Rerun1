import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping
// swiftlint:disable force_try
// swiftlint:disable number_separator

final class LoadImageCommentsFromRemoteUseCaseTests: XCTestCase {
    func test_load_deliversErrorOnNon2xxHTTPResponse() {
        let (sut, client) = makeSUT()
        
        let statusCodes = [199, 150, 300, 400, 500]
        statusCodes.enumerated().forEach { index, statusCode in
            expect(sut, toCompleteWithResult: failure(.invalidData)) {
                let json = makeFeedJSON([])
                client.complete(with: statusCode, data: json, at: index)
            }
        }
    }
    
    func test_load_deliversErrorOn2xxHTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        
        let statusCodes = [200, 201, 250, 280, 299]
        statusCodes.enumerated().forEach { index, statusCode in
            expect(sut, toCompleteWithResult: failure(.invalidData)) {
                let invalidJSON = Data("invalid json".utf8)
                client.complete(with: statusCode, data: invalidJSON, at: index)
            }
        }
    }
    
    func test_load_deliversNoItemsOn2xxHTTPResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()
        
        let statusCodes = [200, 201, 250, 280, 299]
        statusCodes.enumerated().forEach { index, statusCode in
            expect(sut, toCompleteWithResult: .success([])) {
                let emptyListJSON = makeFeedJSON([])
                client.complete(with: statusCode, data: emptyListJSON, at: index)
            }
        }
    }
    
    func test_load_deliversItemsOn2xxHTTPResponseWithNoJSONItems() {
        let (sut, client) = makeSUT()
        let item1 = makeItem(
            id: UUID(),
            message: "a message",
            createdAt: (Date(timeIntervalSince1970: 1598627222), "2020-08-28T15:07:02+00:00"),
            username: "a username"
        )
        let item2 = makeItem(
            id: UUID(),
            message: "another message",
            createdAt: (Date(timeIntervalSince1970: 1577881882), "2020-01-01T12:31:22+00:00"),
            username: "another username"
        )
        let items = [item1, item2]
        
        let statusCodes = [200, 201, 250, 280, 299]
        statusCodes.enumerated().forEach { index, statusCode in
            expect(sut, toCompleteWithResult: .success(items.map { $0.model })) {
                let json = makeFeedJSON(items.map { $0.json })
                client.complete(with: statusCode, data: json, at: index)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        url: URL = URL(string: "https://a-url.com")!,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: RemoteImageCommentsLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteImageCommentsLoader(url: url, client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }
    
    private func expect(
        _ sut: RemoteImageCommentsLoader,
        toCompleteWithResult expectedResult: RemoteImageCommentsLoader.LoadResult,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for load completion")
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
                
            case let (.failure(receivedError as RemoteImageCommentsLoader.LoadError),
                      .failure(expectedError as RemoteImageCommentsLoader.LoadError)):
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
        message: String,
        createdAt: (date: Date, iso8601String: String),
        username: String
    ) -> (model: ImageComment, json: [String: Any]) {
        let model = ImageComment(
            id: id,
            message: message,
            createdAt: createdAt.date,
            username: username
        )
        let json = [
            "id": id.uuidString,
            "message": model.message,
            "created_at": createdAt.iso8601String,
            "author": ["username": username]
        ].compactMapValues { $0 }
        return (model, json)
    }
    
    private func makeFeedJSON(_ items: [[String: Any]]) -> Data {
        let json = ["items": items]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func failure(_ error: RemoteImageCommentsLoader.LoadError) -> RemoteImageCommentsLoader.LoadResult {
        return .failure(error)
    }
}

// swiftlint:enable force_unwrapping
// swiftlint:enable force_try
// swiftlint:enable number_separator
