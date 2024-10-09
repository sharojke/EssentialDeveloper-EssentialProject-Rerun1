import XCTest

protocol FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel)
}

protocol FeedErrorView {
    func display(_ viewModel: FeedErrorViewModel)
}

struct FeedErrorViewModel {
    let message: String?
    
    static func noError() -> Self {
        return Self(message: nil)
    }
}

struct FeedLoadingViewModel {
    let isLoading: Bool
}

final class FeedPresenter {
    private let errorView: FeedErrorView
    private let loadingView: FeedLoadingView
    
    init(errorView: FeedErrorView, loadingView: FeedLoadingView) {
        self.errorView = errorView
        self.loadingView = loadingView
    }
    
    func didStartLoadingFeed() {
        errorView.display(.noError())
        loadingView.display(FeedLoadingViewModel(isLoading: true))
    }
}

// swiftlint:disable:next file_types_order
final class FeedPresenterTests: XCTestCase {
    func test_init_doesNotSendMessagesToView() {
        let (_, view) = makeSUT()
        
        XCTAssertTrue(view.messages.isEmpty)
    }
    
    func test_didStartLoadingFeed_doesNotSendMessagesToViewAndStartsLoading() {
        let (presenter, view) = makeSUT()
        
        presenter.didStartLoadingFeed()
                
        XCTAssertEqual(
            view.messages,
            [
                .displayErrorMessage(nil),
                .displayIsLoading(true)
            ]
        )
    }
    
    // MARK: Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: FeedPresenter, view: ViewSpy) {
        let view = ViewSpy()
        let presenter = FeedPresenter(errorView: view, loadingView: view)
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(presenter, file: file, line: line)
        return (presenter, view)
    }
}

private final class ViewSpy {
    enum Message: Equatable {
        case displayErrorMessage(String?)
        case displayIsLoading(Bool)
    }
    
    private(set) var messages = [Message]()
}

extension ViewSpy: FeedErrorView {
    func display(_ viewModel: FeedErrorViewModel) {
        messages.append(.displayErrorMessage(viewModel.message))
    }
}

extension ViewSpy: FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel) {
        messages.append(.displayIsLoading(viewModel.isLoading))
    }
}
