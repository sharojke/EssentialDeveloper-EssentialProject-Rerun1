import EssentialFeed
import XCTest

// swiftlint:disable:next file_types_order
final class LoadResourcePresenterTests: XCTestCase {
    func test_init_doesNotSendMessagesToView() {
        let (_, view) = makeSUT()
        
        XCTAssertTrue(view.messages.isEmpty)
    }
    
    func test_didStartLoading_displaysNoErrorMessageAndStartsLoading() {
        let (presenter, view) = makeSUT()
        
        presenter.didStartLoading()
                
        XCTAssertEqual(
            view.messages,
            [
                .displayErrorMessage(nil),
                .displayIsLoading(true)
            ]
        )
    }
    
    func test_didFinishLoadingResource_displaysResourceAndStopsLoading() {
        let (presenter, view) = makeSUT { resource in
            return resource + " view model"
        }
        
        presenter.didFinishLoading(with: "resource")
                
        XCTAssertEqual(
            view.messages,
            [
                .displayViewModel("resource view model"),
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
        mapper: @escaping LoadResourcePresenter.Mapper = { _ in "any" },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: LoadResourcePresenter, view: ViewSpy) {
        let view = ViewSpy()
        let presenter = LoadResourcePresenter(
            resourceView: view,
            loadingView: view,
            errorView: view,
            mapper: mapper
        )
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
        case displayViewModel(String)
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

extension ViewSpy: ResourceView {
    func display(_ viewModel: String) {
        messages.insert(.displayViewModel(viewModel))
    }
}
