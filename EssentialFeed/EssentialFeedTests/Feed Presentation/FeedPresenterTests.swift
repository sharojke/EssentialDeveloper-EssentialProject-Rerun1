import EssentialFeed
import XCTest

protocol FeedView {
    func display(_ viewModel: FeedViewModel)
}

protocol FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel)
}

protocol FeedErrorView {
    func display(_ viewModel: FeedErrorViewModel)
}

struct FeedViewModel {
    let feed: [FeedImage]
}

struct FeedLoadingViewModel {
    let isLoading: Bool
}

struct FeedErrorViewModel {
    let message: String?
    
    static func noError() -> Self {
        return Self(message: nil)
    }
}

final class FeedPresenter {
    private let feedView: FeedView
    private let loadingView: FeedLoadingView
    private let errorView: FeedErrorView
    
    init(feedView: FeedView, loadingView: FeedLoadingView, errorView: FeedErrorView) {
        self.feedView = feedView
        self.loadingView = loadingView
        self.errorView = errorView
    }
    
    func didStartLoadingFeed() {
        errorView.display(.noError())
        loadingView.display(FeedLoadingViewModel(isLoading: true))
    }
    
    func didFinishLoadingFeed(with feed: [FeedImage]) {
        feedView.display(FeedViewModel(feed: feed))
        loadingView.display(FeedLoadingViewModel(isLoading: false))
    }
}

// swiftlint:disable:next file_types_order
final class FeedPresenterTests: XCTestCase {
    func test_init_doesNotSendMessagesToView() {
        let (_, view) = makeSUT()
        
        XCTAssertTrue(view.messages.isEmpty)
    }
    
    func test_didStartLoadingFeed_displaysNoErrorMessageAndStartsLoading() {
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
    
    func test_didFinishLoadingFeed_displaysFeedAndStopsLoading() {
        let (presenter, view) = makeSUT()
        let feed = [uniqueImage()]
        
        presenter.didFinishLoadingFeed(with: feed)
                
        XCTAssertEqual(
            view.messages,
            [
                .displayFeed(feed),
                .displayIsLoading(false)
            ]
        )
    }
    
    // MARK: Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: FeedPresenter, view: ViewSpy) {
        let view = ViewSpy()
        let presenter = FeedPresenter(feedView: view, loadingView: view, errorView: view)
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(presenter, file: file, line: line)
        return (presenter, view)
    }
}

private final class ViewSpy {
    enum Message: Hashable {
        case displayErrorMessage(String?)
        case displayIsLoading(Bool)
        case displayFeed([FeedImage])
    }
    
    private(set) var messages = Set<Message>()
}

extension ViewSpy: FeedErrorView {
    func display(_ viewModel: FeedErrorViewModel) {
        messages.insert(.displayErrorMessage(viewModel.message))
    }
}

extension ViewSpy: FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel) {
        messages.insert(.displayIsLoading(viewModel.isLoading))
    }
}

extension ViewSpy: FeedView {
    func display(_ viewModel: FeedViewModel) {
        messages.insert(.displayFeed(viewModel.feed))
    }
}
