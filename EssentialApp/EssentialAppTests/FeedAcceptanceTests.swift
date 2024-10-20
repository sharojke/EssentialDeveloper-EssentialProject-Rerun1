@testable import EssentialApp
import EssentialFeed
import EssentialFeediOS
import XCTest

// swiftlint:disable force_unwrapping
// swiftlint:disable force_cast

final class FeedAcceptanceTests: XCTestCase {
    func test_onLaunch_displaysRemoteFeedWhenCustomerHasConnectivity() {
        let feed = launch(httpClient: HTTPClientStub.online(response), store: InMemoryFeedStore.empty)
        
        XCTAssertEqual(feed.numberOfRenderedFeedImageViews(), 2)
        XCTAssertEqual(feed.renderedFeedImageData(at: 0), makeImageData())
        XCTAssertEqual(feed.renderedFeedImageData(at: 1), makeImageData())
    }
    
    func test_onLaunch_displaysCachedFeedWhenCustomerHasNoConnectivity() {
        let sharedStore = InMemoryFeedStore.empty
        let onlineFeed = launch(httpClient: HTTPClientStub.online(response), store: sharedStore)
        onlineFeed.simulateFeedImageViewVisible(at: .zero)
        onlineFeed.simulateFeedImageViewVisible(at: 1)
        
        let offlineFeed = launch(httpClient: HTTPClientStub.offline(), store: sharedStore)

        XCTAssertEqual(offlineFeed.numberOfRenderedFeedImageViews(), 2)
        XCTAssertEqual(offlineFeed.renderedFeedImageData(at: 0), makeImageData())
        XCTAssertEqual(offlineFeed.renderedFeedImageData(at: 1), makeImageData())
    }
    
    func test_onLaunch_displaysEmptyFeedOnNoConnectivityAndNoCache() {
        let feed = launch(httpClient: HTTPClientStub.offline(), store: InMemoryFeedStore.empty)
        
        XCTAssertEqual(feed.numberOfRenderedFeedImageViews(), 0)
    }
    
    func test_onEnteringBackground_deletesExpiredFeedCache() {
        let store = InMemoryFeedStore.withExpiredFeedCache
        
        enterBackground(with: store)
        
        XCTAssertNil(store.feedCache, "Expected to delete expired cache")
    }
    
    func test_onEnteringBackground_keepsNonExpiredFeedCache() {
        let store = InMemoryFeedStore.withNonExpiredFeedCache
        
        enterBackground(with: store)
        
        XCTAssertNotNil(store.feedCache, "Expected to keep non-expired cache")
    }
    
    // MARK: Helpers
    
    private func launch(
        httpClient: HTTPClient = HTTPClientStub.offline(),
        store: FeedStore & FeedImageDataStore = InMemoryFeedStore.empty
    ) -> FeedViewController {
        let sut = SceneDelegate(httpClient: httpClient, store: store)
        sut.window = UIWindow()
        sut.configureWindow()
        
        let navigation = sut.window?.rootViewController as? UINavigationController
        let feed = navigation?.topViewController as! FeedViewController
        feed.simulateAppearance()
        return feed
    }
    
    private func enterBackground(with store: InMemoryFeedStore) {
        let sut = SceneDelegate(httpClient: HTTPClientStub.offline(), store: store)
        sut.sceneWillResignActive(UIApplication.shared.connectedScenes.first!)
    }
    
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
// swiftlint:enable force_cast