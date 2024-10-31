import EssentialFeed
import XCTest

// swiftlint:disable:next file_types_order
final class FeedImagePresenterTests: XCTestCase {
    func test_map_createdViewModel() {
        let image = uniqueImage()
        
        let viewModel = FeedImagePresenter<ViewSpy, AnyImage>.map(image)
        
        XCTAssertEqual(viewModel.description, image.description)
        XCTAssertEqual(viewModel.location, image.location)
    }
    
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
        
        presenter.didFinishLoadingImage(with: Data(), for: image)
        
        let message = view.messages.first
        XCTAssertEqual(view.messages.count, 1)
        XCTAssertEqual(message?.description, image.description)
        XCTAssertEqual(message?.location, image.location)
        XCTAssertEqual(message?.isLoading, false)
        XCTAssertEqual(message?.shouldRetry, true)
        XCTAssertNil(message?.image)
    }
    
    func test_didFinishLoadingImage_displaysImageOnSuccessfulImageTransformation() {
        let transformedImage = AnyImage()
        let (presenter, view) = makeSUT(imageTransformer: { _ in transformedImage })
        let image = uniqueImage()
        
        presenter.didFinishLoadingImage(with: Data(), for: image)
        
        let message = view.messages.first
        XCTAssertEqual(view.messages.count, 1)
        XCTAssertEqual(message?.description, image.description)
        XCTAssertEqual(message?.location, image.location)
        XCTAssertEqual(message?.isLoading, false)
        XCTAssertEqual(message?.shouldRetry, false)
        XCTAssertNotNil(message?.image)
    }
    
    // MARK: Helpers
    
    private func makeSUT(
        imageTransformer: @escaping (Data) -> AnyImage? = { _ in nil },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: FeedImagePresenter<ViewSpy, AnyImage>, view: ViewSpy) {
        let view = ViewSpy()
        let presenter = FeedImagePresenter(view: view, imageTransformer: imageTransformer)
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(presenter, file: file, line: line)
        return (presenter, view)
    }
    
    private func fail() -> (Data) -> AnyImage? {
        return { _ in nil }
    }
}

private struct AnyImage: Equatable {}

private final class ViewSpy {
    private(set) var messages = [FeedImageLoadingViewModel<AnyImage>]()
}

extension ViewSpy: FeedImageLoadingView {
    func display(_ viewModel: FeedImageLoadingViewModel<AnyImage>) {
        messages.append(viewModel)
    }
}
