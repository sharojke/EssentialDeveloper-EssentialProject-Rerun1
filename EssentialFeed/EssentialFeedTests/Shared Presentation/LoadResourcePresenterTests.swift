import EssentialFeed
import XCTest

// swiftlint:disable:next file_types_order
final class LoadResourcePresenterTests: XCTestCase {
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
    
    func test_didFinishLoadingFeedWithError_displaysLocalizedErrorMessageAndStopsLoading() {
        let (presenter, view) = makeSUT()
        
        presenter.didFinishLoadingFeed(with: anyNSError())
                
        XCTAssertEqual(
            view.messages,
            [
                .displayErrorMessage(localized("FEED_VIEW_CONNECTION_ERROR")),
                .displayIsLoading(false)
            ]
        )
    }
    
    // MARK: Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: LoadResourcePresenter, view: ViewSpy) {
        let view = ViewSpy()
        let presenter = LoadResourcePresenter(feedView: view, loadingView: view, errorView: view)
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(presenter, file: file, line: line)
        return (presenter, view)
    }
    
    private func localized(_ key: String, file: StaticString = #filePath, line: UInt = #line) -> String {
        let table = "Feed"
        let bundle = Bundle(for: LoadResourcePresenter.self)
        let value = bundle.localizedString(forKey: key, value: nil, table: table)
        if value == key {
            XCTFail("Missing localized string for key: \(key) in table: \(table)", file: file, line: line)
        }
        return value
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
