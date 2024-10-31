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
    
    func test_didFinishLoadingWithError_displaysLocalizedErrorMessageAndStopsLoading() {
        let (presenter, view) = makeSUT()
        
        presenter.didFinishLoading(with: anyNSError())
                
        XCTAssertEqual(
            view.messages,
            [
                .displayErrorMessage(localized("GENERIC_VIEW_CONNECTION_ERROR")),
                .displayIsLoading(false)
            ]
        )
    }
    
    // MARK: Helpers
    
    private func makeSUT(
        mapper: @escaping LoadResourcePresenter<String, ViewSpy>.Mapper = { _ in "any" },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: LoadResourcePresenter<String, ViewSpy>, view: ViewSpy) {
        let view = ViewSpy()
        let presenter = LoadResourcePresenter<String, ViewSpy>(
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
        let table = "Shared"
        let bundle = Bundle(for: LoadResourcePresenter<String, ViewSpy>.self)
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

extension ViewSpy: ResourceErrorView {
    func display(_ viewModel: ResourceErrorViewModel) {
        messages.insert(.displayErrorMessage(viewModel.message))
    }
}

extension ViewSpy: ResourceLoadingView {
    func display(_ viewModel: ResourceLoadingViewModel) {
        messages.insert(.displayIsLoading(viewModel.isLoading))
    }
}

extension ViewSpy: ResourceView {
    typealias ResourceViewModel = String
    
    func display(_ viewModel: ResourceViewModel) {
        messages.insert(.displayViewModel(viewModel))
    }
}
