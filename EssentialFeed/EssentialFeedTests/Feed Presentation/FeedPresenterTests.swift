import XCTest

protocol FeedErrorView {
    func display(_ viewModel: FeedErrorViewModel)
}

struct FeedErrorViewModel {
    let message: String?
    
    static func noError() -> Self {
        return Self(message: nil)
    }
}

final class FeedPresenter {
    private let errorView: FeedErrorView
    
    init(errorView: FeedErrorView) {
        self.errorView = errorView
    }
    
    func didStartLoadingFeed() {
        errorView.display(.noError())
    }
}

// swiftlint:disable:next file_types_order
final class FeedPresenterTests: XCTestCase {
    func test_init_doesNotSendMessagesToView() {
        let (_, view) = makeSUT()
        
        XCTAssertTrue(view.messages.isEmpty)
    }
    
    func test_didStartLoadingFeed_doesNotSendMessagesToView() {
        let (presenter, view) = makeSUT()
        
        presenter.didStartLoadingFeed()
        
        XCTAssertEqual(view.messages, [.display(errorMessage: nil)])
    }
    
    // MARK: Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: FeedPresenter, view: ViewSpy) {
        let view = ViewSpy()
        let presenter = FeedPresenter(errorView: view)
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(presenter, file: file, line: line)
        return (presenter, view)
    }
}

private final class ViewSpy {
    enum Message: Equatable {
        case display(errorMessage: String?)
    }
    
    private(set) var messages = [Message]()
}

extension ViewSpy: FeedErrorView {
    func display(_ viewModel: FeedErrorViewModel) {
        messages.append(.display(errorMessage: viewModel.message))
    }
}
