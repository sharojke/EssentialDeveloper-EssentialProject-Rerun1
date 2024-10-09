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

private struct InvalidImageDataError: Error {}

final class FeedImagePresenter {
    private let view: FeedImageLoadingView
    private let imageTransformer: (Data) -> Any?
    
    init(view: FeedImageLoadingView, imageTransformer: @escaping (Data) -> Any?) {
        self.view = view
        self.imageTransformer = imageTransformer
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
    
    func didFinishLoadingImage(with data: Data, for model: FeedImage) {
        guard let image = imageTransformer(data) else {
            return didFinishLoadingImage(with: InvalidImageDataError(), for: model)
        }
        
        let viewModel = FeedImageLoadingViewModel(
            description: model.description,
            location: model.location,
            image: image,
            isLoading: false,
            shouldRetry: false
        )
        view.display(viewModel)
    }
    
    func didFinishLoadingImage(with error: Error, for model: FeedImage) {
        let viewModel = FeedImageLoadingViewModel(
            description: model.description,
            location: model.location,
            image: nil,
            isLoading: false,
            shouldRetry: true
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
    
    func test_didStartLoadingImageWithError_displaysRetry() {
        let (presenter, view) = makeSUT()
        let image = uniqueImage()
        
        presenter.didFinishLoadingImage(with: anyNSError(), for: image)
        
        let message = view.messages.first
        XCTAssertEqual(view.messages.count, 1)
        XCTAssertEqual(message?.description, image.description)
        XCTAssertEqual(message?.location, image.location)
        XCTAssertEqual(message?.isLoading, false)
        XCTAssertEqual(message?.shouldRetry, true)
        XCTAssertNil(message?.image)
    }
    
    func test_didFinishLoadingImage_displaysRetryOnFailedImageTransformation() {
        let (presenter, view) = makeSUT(imageTransformer: fail())
        let image = uniqueImage()
        let data = Data()
        
        presenter.didFinishLoadingImage(with: data, for: image)
        
        let message = view.messages.first
        XCTAssertEqual(view.messages.count, 1)
        XCTAssertEqual(message?.description, image.description)
        XCTAssertEqual(message?.location, image.location)
        XCTAssertEqual(message?.isLoading, false)
        XCTAssertEqual(message?.shouldRetry, true)
        XCTAssertNil(message?.image)
    }
    
    // MARK: Helpers
    
    private func makeSUT(
        imageTransformer: @escaping (Data) -> Any? = { _ in nil },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: FeedImagePresenter, view: ViewSpy) {
        let view = ViewSpy()
        let presenter = FeedImagePresenter(view: view, imageTransformer: imageTransformer)
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(presenter, file: file, line: line)
        return (presenter, view)
    }
    
    private func fail() -> (Data) -> Any? {
        return { _ in nil }
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
