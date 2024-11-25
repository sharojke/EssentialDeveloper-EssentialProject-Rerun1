@testable import EssentialApp
import EssentialFeed
import EssentialFeediOS
import XCTest

// swiftlint:disable force_try
// swiftlint:disable force_unwrapping
// swiftlint:disable force_cast

final class FeedAcceptanceTests: XCTestCase {
    func test_onLaunch_displaysRemoteFeedWhenCustomerHasConnectivity() throws {
        let feed = launch(store: try CoreDataFeedStore.empty, httpClient: HTTPClientStub.online(response))
        
        XCTAssertEqual(feed.numberOfRenderedFeedImageViews(), 2)
        XCTAssertEqual(feed.renderedFeedImageData(at: 0), makeImageData0())
        XCTAssertEqual(feed.renderedFeedImageData(at: 1), makeImageData1())
        XCTAssertTrue(feed.canLoadMoreFeed())
        
        feed.simulateLoadMoreFeedAction()
        XCTAssertEqual(feed.numberOfRenderedFeedImageViews(), 3)
        XCTAssertEqual(feed.renderedFeedImageData(at: 0), makeImageData0())
        XCTAssertEqual(feed.renderedFeedImageData(at: 1), makeImageData1())
        XCTAssertEqual(feed.renderedFeedImageData(at: 2), makeImageData2())
        XCTAssertTrue(feed.canLoadMoreFeed())
        
        feed.simulateLoadMoreFeedAction()
        XCTAssertEqual(feed.numberOfRenderedFeedImageViews(), 3)
        XCTAssertEqual(feed.renderedFeedImageData(at: 0), makeImageData0())
        XCTAssertEqual(feed.renderedFeedImageData(at: 1), makeImageData1())
        XCTAssertEqual(feed.renderedFeedImageData(at: 2), makeImageData2())
        XCTAssertFalse(feed.canLoadMoreFeed())
    }
    
    func test_onLaunch_displaysCachedFeedWhenCustomerHasNoConnectivity() throws {
        let sharedStore = try CoreDataFeedStore.empty
        
        let onlineFeed = launch(store: sharedStore, httpClient: HTTPClientStub.online(response))
        onlineFeed.simulateFeedImageViewVisible(at: .zero)
        onlineFeed.simulateFeedImageViewVisible(at: 1)
        onlineFeed.simulateLoadMoreFeedAction()
        onlineFeed.simulateFeedImageViewVisible(at: 2)
        
        let offlineFeed = launch(store: sharedStore, httpClient: HTTPClientStub.offline())
        XCTAssertEqual(offlineFeed.numberOfRenderedFeedImageViews(), 3)
        XCTAssertEqual(offlineFeed.renderedFeedImageData(at: 0), makeImageData0())
        XCTAssertEqual(offlineFeed.renderedFeedImageData(at: 1), makeImageData1())
        XCTAssertEqual(offlineFeed.renderedFeedImageData(at: 2), makeImageData2())
    }
    
    func test_onLaunch_displaysEmptyFeedOnNoConnectivityAndNoCache() throws {
        let feed = launch(store: try CoreDataFeedStore.empty, httpClient: HTTPClientStub.offline())
        
        XCTAssertEqual(feed.numberOfRenderedFeedImageViews(), 0)
    }
    
    func test_onEnteringBackground_deletesExpiredFeedCache() throws {
        let store = try CoreDataFeedStore.withExpiredFeedCache
        
        enterBackground(with: store)
        
        XCTAssertNil(try store.retrieve(), "Expected to delete expired cache")
    }
    
    func test_onEnteringBackground_keepsNonExpiredFeedCache() throws {
        let store = try CoreDataFeedStore.withNonExpiredFeedCache
        
        enterBackground(with: store)
        
        XCTAssertNotNil(try store.retrieve(), "Expected to keep non-expired cache")
    }
    
    func test_onFeedImageSelection_displaysComments() throws {
        let comments = try showCommentsForFirstImage()
        
        XCTAssertEqual(comments.numberOfRenderedCommentsViews(), 1)
        XCTAssertEqual(comments.commentMessage(at: .zero), makeCommentMessage())
    }
    
    // MARK: Helpers
    
    private func launch(
        store: CoreDataFeedStore,
        httpClient: HTTPClient = HTTPClientStub.offline()
    ) -> ListViewController {
        let sut = SceneDelegate(httpClient: httpClient, store: store)
        sut.window = smallWindowToPreventLoadingContentAheadOfTime()
        sut.configureWindow()
        
        let navigation = sut.window?.rootViewController as? UINavigationController
        let feed = navigation?.topViewController as! ListViewController
        feed.simulateAppearance()
        return feed
    }
    
    private func smallWindowToPreventLoadingContentAheadOfTime() -> UIWindow {
        return UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 1))
    }
    
    private func enterBackground(with store: CoreDataFeedStore) {
        let sut = SceneDelegate(httpClient: HTTPClientStub.offline(), store: store)
        sut.sceneWillResignActive(UIApplication.shared.connectedScenes.first!)
    }
    
    private func response(for url: URL) -> (Data, HTTPURLResponse) {
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (makeData(for: url), response)
    }
    
    private func makeData(for url: URL) -> Data {
        switch url.path {
        case "/image-0":
            return makeImageData0()
            
        case  "/image-1":
            return makeImageData1()
            
        case "/image-2":
            return makeImageData2()
            
        case "/essential-feed/v1/feed" where url.query?.contains("after_id") == false:
            return makeFirstFeedPageData()
            
        case "/essential-feed/v1/feed" where url.query?
                .contains("after_id=A28F5FE3-27A7-44E9-8DF5-53742D0E4A5A") == true:
            return makeSecondFeedPageData()
            
        case "/essential-feed/v1/feed" where url.query?
                .contains("after_id=166FCDD7-C9F4-420A-B2D6-CE2EAFA3D82F") == true:
            return makeLastEmptyFeedPageData()
            
        case "/essential-feed/v1/image/2AB2AE66-A4B7-4A16-B374-51BBAC8DB086/comments":
            return makeCommentsData()
            
        default:
            return Data()
        }
    }
    
    private func makeImageData0() -> Data {
        return UIImage.make(withColor: .red).pngData()!
    }
    
    private func makeImageData1() -> Data {
        return UIImage.make(withColor: .blue).pngData()!
    }
    
    private func makeImageData2() -> Data {
        return UIImage.make(withColor: .green).pngData()!
    }
    
    private func makeFirstFeedPageData() -> Data {
        return try! JSONSerialization.data(
            withJSONObject: [
                "items": [
                    ["id": "2AB2AE66-A4B7-4A16-B374-51BBAC8DB086", "image": "http://feed.com/image-0"],
                    ["id": "A28F5FE3-27A7-44E9-8DF5-53742D0E4A5A", "image": "http://feed.com/image-1"]
                ]
            ]
        )
    }
    
    private func makeSecondFeedPageData() -> Data {
        return try! JSONSerialization.data(
            withJSONObject: [
                "items": [
                    ["id": "166FCDD7-C9F4-420A-B2D6-CE2EAFA3D82F", "image": "http://feed.com/image-2"]
                ]
            ]
        )
    }
    
    private func makeLastEmptyFeedPageData() -> Data {
        return try! JSONSerialization.data(withJSONObject: ["items": []])
    }
    
    private func showCommentsForFirstImage(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> ListViewController {
        let feed = launch(store: try CoreDataFeedStore.empty, httpClient: HTTPClientStub.online(response))
        
        feed.simulateTapOnFeedImage(at: .zero)
        RunLoop.current.run(until: Date())
        
        let navigation = feed.navigationController
        let comments = try XCTUnwrap(
            navigation?.topViewController as? ListViewController,
            file: file,
            line: line
        )
        comments.simulateAppearance()
        return comments
    }
    
    private func makeCommentsData() -> Data {
        return try! JSONSerialization.data(
            withJSONObject: [
                "items": [
                    [
                        "id": UUID().uuidString,
                        "message": makeCommentMessage(),
                        "created_at": "2020-05-20T11:24:59+0000",
                        "author": ["username": "a username"]
                    ]
                ]
            ]
        )
    }
    
    private func makeCommentMessage() -> String {
        return "a message"
    }
}

private extension CoreDataFeedStore {
    static var empty: CoreDataFeedStore {
        get throws {
            try CoreDataFeedStore(storeURL: URL(fileURLWithPath: "/dev/null"), contextQueue: .main)
        }
    }
    
    static var withExpiredFeedCache: CoreDataFeedStore {
        get throws {
            let store = try CoreDataFeedStore.empty
            try store.insert([], timestamp: .distantPast)
            return store
        }
    }
    
    static var withNonExpiredFeedCache: CoreDataFeedStore {
        get throws {
            let store = try CoreDataFeedStore.empty
            try store.insert([], timestamp: Date())
            return store
        }
    }
}

// swiftlint:enable force_try
// swiftlint:enable force_unwrapping
// swiftlint:enable force_cast
