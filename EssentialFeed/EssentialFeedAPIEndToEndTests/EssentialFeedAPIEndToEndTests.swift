import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping

final class EssentialFeedAPIEndToEndTests: XCTestCase {
    func test_endToEndServerGETFeedResult_matchesFixedTestAccountData() {
        switch getFeedResult() {
        case .success(let feed):
            XCTAssertEqual(feed.count, 8, "Expected 8 images in the test account image feed")
            XCTAssertEqual(feed[0], expectedImage(at: 0))
            XCTAssertEqual(feed[1], expectedImage(at: 1))
            XCTAssertEqual(feed[2], expectedImage(at: 2))
            XCTAssertEqual(feed[3], expectedImage(at: 3))
            XCTAssertEqual(feed[4], expectedImage(at: 4))
            XCTAssertEqual(feed[5], expectedImage(at: 5))
            XCTAssertEqual(feed[6], expectedImage(at: 6))
            XCTAssertEqual(feed[7], expectedImage(at: 7))
            
        case .failure(let error):
            XCTFail("Expected success, got \(error) instead")
            
        case .none:
            XCTFail("Expected success, got no result instead")
        }
    }
    
    func test_endToEndTestServerGETFeedImageDataResult_matchesFixedTestAccountData() {
        switch getFeedImageDataResult() {
        case .success(let data):
            XCTAssertFalse(data.isEmpty, "Expected non-empty image data")
            
        case let .failure(error)?:
            XCTFail("Expected successful image data result, got \(error) instead")
            
        default:
            XCTFail("Expected successful image data result, got no result instead")
        }
    }
    
    // MARK: - Helpers
    
    private func getFeedResult(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> FeedLoader.LoadResult? {
        let testServerURL = URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed")!
        let client = ephemeralClient(file: file, line: line)
        let loader = RemoteLoader(url: testServerURL, client: client, mapper: FeedItemsMapper.map)
        trackForMemoryLeaks(loader, file: file, line: line)
        
        let exp = expectation(description: "Wait for load completion")
        var receivedResult: FeedLoader.LoadResult?
        loader.load { result in
            receivedResult = result
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 20)
        return receivedResult
    }

    private func expectedImage(at index: Int) -> FeedImage {
        return FeedImage(
            id: id(at: index),
            description: description(at: index),
            location: location(at: index),
            url: url(at: index)
        )
    }
    
    private func id(at index: Int) -> UUID {
        let uuidStrings = [
            "73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6",
            "BA298A85-6275-48D3-8315-9C8F7C1CD109",
            "5A0D45B3-8E26-4385-8C5D-213E160A5E3C",
            "FF0ECFE2-2879-403F-8DBE-A83B4010B340",
            "DC97EF5E-2CC9-4905-A8AD-3C351C311001",
            "557D87F1-25D3-4D77-82E9-364B2ED9CB30",
            "A83284EF-C2DF-415D-AB73-2A9B8B04950B",
            "F79BD7F8-063F-46E2-8147-A67635C3BB01"
        ]
        return UUID(uuidString: uuidStrings[index])!
    }
    
    private func description(at index: Int) -> String? {
        return [
            "Description 1",
            nil,
            "Description 3",
            nil,
            "Description 5",
            "Description 6",
            "Description 7",
            "Description 8"
        ][index]
    }
    
    private func location(at index: Int) -> String? {
        return [
            "Location 1",
            "Location 2",
            nil,
            nil,
            "Location 5",
            "Location 6",
            "Location 7",
            "Location 8"
        ][index]
    }
    
    private func url(at index: Int) -> URL {
        return URL(string: "https://url-\(index + 1).com")!
    }
    
    private func getFeedImageDataResult(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> FeedImageDataLoader.LoadImageResult? {
        let testServerURL = URL(string: "https://ile-api.essentialdeveloper.com/essential-feed/v1/feed")!
        let client = ephemeralClient(file: file, line: line)
        let loader = RemoteFeedImageDataLoader(client: client)
        trackForMemoryLeaks(loader, file: file, line: line)
        
        let exp = expectation(description: "Wait for load completion")
        var receivedResult: FeedImageDataLoader.LoadImageResult?
        _ = loader.loadImageData(from: testServerURL) { result in
            receivedResult = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)
        
        return receivedResult
    }
    
    private func ephemeralClient(file: StaticString = #filePath, line: UInt = #line) -> HTTPClient {
        let client = URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
        trackForMemoryLeaks(client, file: file, line: line)
        return client
    }
}

// swiftlint:enable force_unwrapping
