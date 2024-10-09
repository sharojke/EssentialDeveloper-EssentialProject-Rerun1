import EssentialFeed
import XCTest

protocol FeedImageLoadingView {
    func display(_ viewModel: FeedImageLoadingViewModel)
}

struct FeedImageLoadingViewModel {
    let description: String?
    let location: String?
    let image: Any?
    let isLoading: Bool
    let shouldRetry: Bool
    
    var hasLocation: Bool {
        return location != nil
    }
}

final class FeedImagePresenter {
    private let view: FeedImageLoadingView
    
    init(view: FeedImageLoadingView) {
        self.view = view
    }
    
    func didStartLoadingImage(for model: FeedImage) {
        let viewModel = FeedImageLoadingViewModel(
            description: model.description,
            location: model.location,
            image: nil,
            isLoading: true,
            shouldRetry: false
        )
        view.display(viewModel)
    }
}

// swiftlint:disable:next file_types_order
final class FeedImagePresenterTests: XCTestCase {
    func test_init_doesNotSendMessagesToView() {
        let (_, view) = makeSUT()
        
        XCTAssertTrue(view.messages.isEmpty)
    }
    
    func test_didStartLoadingImage_displaysLoadingImage() {
        let (presenter, view) = makeSUT()
        let image = uniqueImage()
        
        presenter.didStartLoadingImage(for: image)
        
        let message = view.messages.first
        XCTAssertEqual(view.messages.count, 1)
        XCTAssertEqual(message?.description, image.description)
        XCTAssertEqual(message?.location, image.location)
        XCTAssertEqual(message?.isLoading, true)
        XCTAssertEqual(message?.shouldRetry, false)
        XCTAssertNil(message?.image)
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
    private(set) var messages = [FeedImageLoadingViewModel]()
}

extension ViewSpy: FeedImageLoadingView {
    func display(_ viewModel: FeedImageLoadingViewModel) {
        messages.append(viewModel)
    }
}
