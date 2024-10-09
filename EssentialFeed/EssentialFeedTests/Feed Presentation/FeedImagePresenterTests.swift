import XCTest

final class FeedImagePresenter {
    private let view: Any
    
    init(view: Any) {
        self.view = view
    }
}

// swiftlint:disable:next file_types_order
final class FeedImagePresenterTests: XCTestCase {
    func test_init_doesNotSendMessagesToView() {
        let (_, view) = makeSUT()
        
        XCTAssertTrue(view.messages.isEmpty)
    }
    
    // MARK: Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: FeedImagePresenter, view: ViewSpy) {
        let view = ViewSpy()
        let presenter = FeedImagePresenter(view: view)
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(presenter, file: file, line: line)
        return (presenter, view)
    }
}

private final class ViewSpy {
    enum Message: Hashable {
    }
    
    private(set) var messages = Set<Message>()
}
