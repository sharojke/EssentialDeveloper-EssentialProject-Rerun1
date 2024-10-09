import XCTest

final class FeedPresenter {
    init(view: Any) {
    }
}

private final class ViewSpy {
    let messages = [Any]()
}

final class FeedPresenterTests: XCTestCase {
    func test_init_doesNotSendMessagesToView() {
        let view = ViewSpy()
        
        _ = FeedPresenter(view: view)
        
        XCTAssertTrue(view.messages.isEmpty)
    }
}
