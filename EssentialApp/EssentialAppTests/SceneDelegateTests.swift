@testable import EssentialApp
import EssentialFeed
import EssentialFeediOS
import XCTest

private class UIWindowSpy: UIWindow {
    var makeKeyAndVisibleCallCount = 0
    
    override func makeKeyAndVisible() {
        makeKeyAndVisibleCallCount += 1
    }
}

final class SceneDelegateTests: XCTestCase {
    func test_configureWindow_setsWindowAsKeyAndVisible() {
        let window = UIWindowSpy()
        let sut = SceneDelegate()
        
        sut.window = window
        sut.configureWindow()
        
        XCTAssertEqual(window.makeKeyAndVisibleCallCount, 1)
    }
    
    func test_configureWindow_configuresRootViewController() {
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
            topController is ListViewController,
            "Expected a feed controller as top view controller, got \(topController as Any) instead"
        )
    }
}
