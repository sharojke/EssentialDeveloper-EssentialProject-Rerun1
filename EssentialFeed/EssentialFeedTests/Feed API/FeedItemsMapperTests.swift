import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping
// swiftlint:disable force_try

final class FeedItemsMapperTests: XCTestCase {
    func test_map_throwsErrorOnNon200HTTPResponse() throws {
        let json = makeFeedJSON([])
        let statusCodes = [199, 201, 300, 400, 500]
        
        try statusCodes.forEach { code in
            XCTAssertThrowsError(
                try FeedItemsMapper.map(json, from: HTTPURLResponse(statusCode: code))
            )
        }
    }
    
    func test_map_throwsErrorOn200HTTPResponseWithInvalidJSON() {
        let invalidJSON = Data("invalid json".utf8)
        
        XCTAssertThrowsError(
            try FeedItemsMapper.map(invalidJSON, from: HTTPURLResponse(statusCode: 200))
        )
    }
    
    func test_map_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() throws {
        let emptyListJSON = makeFeedJSON([])
        
        let result = try FeedItemsMapper.map(emptyListJSON, from: HTTPURLResponse(statusCode: 200))
        
        XCTAssertEqual(result, [])
    }
    
    func test_map_deliversItemsOn200HTTPResponseWithNoJSONItems() throws {
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
        let json = makeFeedJSON(items.map { $0.json })
        
        let result = try FeedItemsMapper.map(json, from: HTTPURLResponse(statusCode: 200))
        
        XCTAssertEqual(result, items.map(\.model))
    }

    // MARK: - Helpers
    
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
}

private extension HTTPURLResponse {
    convenience init(statusCode: Int) {
        self.init(url: anyURL(), statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}

// swiftlint:enable force_unwrapping
// swiftlint:enable force_try
