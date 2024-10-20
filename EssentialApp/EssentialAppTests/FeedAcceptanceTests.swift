@testable import EssentialApp
import EssentialFeed
import EssentialFeediOS
import XCTest

// swiftlint:disable force_unwrapping

private final class HTTPClientStub: HTTPClient {
    private final class Task: HTTPClientTask {
        func cancel() {}
    }
    
    private let stub: (URL) -> GetResult
    
    init(stub: @escaping (URL) -> GetResult) {
        self.stub = stub
    }
    
    static func offline() -> HTTPClientStub {
        return HTTPClientStub { _ in .failure(anyError()) }
    }
    
    static func online(_ stub: @escaping (URL) -> (Data, HTTPURLResponse)) -> HTTPClientStub {
        return HTTPClientStub { .success(stub($0)) }
    }
    
    func get(from url: URL, completion: @escaping (GetResult) -> Void) -> HTTPClientTask {
        completion(stub(url))
        return Task()
    }
}

private final class InMemoryFeedStore: FeedStore, FeedImageDataStore {
    static var empty: InMemoryFeedStore { InMemoryFeedStore() }
    
    private var feedCache: CachedFeed?
    private var feedImageDataCache = [URL: Data]()
    
    func deleteCachedFeed(completion: @escaping FeedStore.DeleteCompletion) {
        feedCache = nil
        completion(.success(Void()))
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertCompletion) {
        feedCache = CachedFeed(feed: feed, timestamp: timestamp)
        completion(.success(Void()))
    }
    
    func retrieve(completion: @escaping FeedStore.RetrieveCompletion) {
        completion(.success(feedCache))
    }
    
    func retrieveData(for url: URL, completion: @escaping FeedImageDataStore.RetrieveCompletion) {
        let data = feedImageDataCache[url]
        completion(.success(data))
    }
    
    func insert(_ data: Data, for url: URL, completion: @escaping FeedImageDataStore.InsertCompletion) {
        feedImageDataCache[url] = data
        completion(.success(Void()))
    }
}

final class FeedAcceptanceTests: XCTestCase {
    func test_onLaunch_displaysRemoteFeedWhenCustomerHasConnectivity() {
        let store = InMemoryFeedStore.empty
        let httpClient = HTTPClientStub.online(response)
        let sut = SceneDelegate(httpClient: httpClient, store: store)
        sut.window = UIWindow()
        sut.configureWindow()
        
        let navigation = sut.window?.rootViewController as? UINavigationController
        let feed = navigation?.topViewController as? FeedViewController
        feed?.simulateAppearance()
        
        XCTAssertEqual(feed?.numberOfRenderedFeedImageViews(), 2)
        XCTAssertNotNil(feed?.simulateFeedImageViewVisible(at: 0).renderedImage)
        XCTAssertNotNil(feed?.simulateFeedImageViewVisible(at: 1).renderedImage)
    }
    
    // MARK: Helpers
    
    private func response(for url: URL) -> (Data, HTTPURLResponse) {
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (makeData(for: url), response)
    }
    
    private func makeData(for url: URL) -> Data {
        switch url.absoluteString {
        case "http://image.com":
            return makeImageData()
            
        default:
            return makeFeedData()
        }
    }
    
    private func makeImageData() -> Data {
        return UIImage.make(withColor: .red).pngData()!
    }
    
    private func makeFeedData() -> Data {
        // swiftlint:disable:next force_try
        return try! JSONSerialization.data(
            withJSONObject: [
                "items": [
                    ["id": UUID().uuidString, "image": "http://image.com"],
                    ["id": UUID().uuidString, "image": "http://image.com"]
                ]
            ]
        )
    }
}

// swiftlint:enable force_unwrapping
