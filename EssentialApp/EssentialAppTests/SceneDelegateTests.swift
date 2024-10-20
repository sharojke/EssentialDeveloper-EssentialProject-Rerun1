@testable import EssentialApp
import EssentialFeed
import EssentialFeediOS
import XCTest

final class SceneDelegateTests: XCTestCase {
    func test_sceneWillConnectToSession_configuresRootViewController() {
        let sut = SceneDelegate()
        sut.window = UIWindow()
        
        sut.configureWindow()
        
        let root = sut.window?.rootViewController
        let rootNavigation = root as? UINavigationController
        let topController = rootNavigation?.topViewController
        
        XCTAssertNotNil(
            rootNavigation,
            "Expected a navigation controller as root, got \(root as Any) instead"
        )
        XCTAssertTrue(
            topController is FeedViewController,
            "Expected a feed controller as top view controller, got \(topController as Any) instead"
        )
    }
}
