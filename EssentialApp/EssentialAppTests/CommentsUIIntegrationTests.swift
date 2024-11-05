import Combine
import EssentialApp
import EssentialFeed
import EssentialFeediOS
import UIKit
import XCTest

// swiftlint:disable force_unwrapping

private final class LoaderSpy: FeedImageDataLoader {
    typealias Publisher = AnyPublisher<[FeedImage], Error>
    
    private final class TaskSpy: FeedImageDataLoaderTask {
        private let onCancel: () -> Void
        
        init(onCancel: @escaping () -> Void) {
            self.onCancel = onCancel
        }
        
        func cancel() {
            onCancel()
        }
    }
    
    private var feedRequests = [PassthroughSubject<[FeedImage], Error>]()
    private var imageRequests = [(url: URL, completion: LoadImageResultCompletion)]()
    private(set) var cancelledImageURLs = [URL]()
    
    var loadedImageURLs: [URL] {
        return imageRequests.map(\.url)
    }
    
    var loadFeedCallCount: Int {
        return feedRequests.count
    }
    
    func loadPublisher() -> Publisher {
        let publisher = PassthroughSubject<[FeedImage], Error>()
        feedRequests.append(publisher)
        return publisher.eraseToAnyPublisher()
    }
    
    func completeFeedLoading(with feed: [FeedImage] = [], at index: Int = .zero) {
        feedRequests[index].send(feed)
    }
    
    func completeFeedLoadingWithError(at index: Int = .zero) {
        feedRequests[index].send(completion: .failure(anyNSError()))
    }
    
    func loadImageData(
        from url: URL,
        completion: @escaping LoadImageResultCompletion
    ) -> FeedImageDataLoaderTask {
        imageRequests.append((url, completion))
        return TaskSpy { [weak self] in
            self?.cancelledImageURLs.append(url)
        }
    }
    
    func completeImageLoading(with imageData: Data = Data(), at index: Int = .zero) {
        imageRequests[index].completion(.success(imageData))
    }
    
    func completeImageLoadingWithError(at index: Int) {
        imageRequests[index].completion(.failure(anyNSError()))
    }
}

final class CommentsUIIntegrationTests: FeedUIIntegrationTests {
    func test_commentsView_hasTitle() {
        let (sut, _) = makeSUT()
        
        sut.simulateAppearance()
        
        XCTAssertEqual(sut.title, commentsTitle)
    }
    
    override func test_loadFeedActions_runsAutomaticallyOnlyOnFirstAppearance() {
            let (sut, loader) = makeSUT()
            XCTAssertEqual(loader.loadFeedCallCount, 0, "Expected no loading requests before view appears")
        
            sut.simulateAppearance()
            XCTAssertEqual(loader.loadFeedCallCount, 1, "Expected a loading request once view appears")
        
            sut.simulateAppearance()
            XCTAssertEqual(loader.loadFeedCallCount, 1, "Expected no loading request the second time view appears")
        }
    
    override func test_loadFeedActions_requestFeedFromLoader() {
        let (sut, loader) = makeSUT()
        XCTAssertEqual(loader.loadFeedCallCount, .zero, "Expected no requests before view is appeared")
        
        sut.simulateAppearance()
        XCTAssertEqual(loader.loadFeedCallCount, 1, "Expected a request after view is appeared")
        
        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(loader.loadFeedCallCount, 2, "Expected another request after initiating a load")
        
        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(loader.loadFeedCallCount, 3, "Expected another request after initiating another load")
    }
    
    override func test_loadingFeedIndicator_isVisibleWhileLoadingFeed() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        XCTAssertTrue(sut.isShowingLoadingIndicator(), "Expected visible after view is appeared")
        
        loader.completeFeedLoading(at: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator(), "Expected hidden after the loading is completed successfully")
        
        sut.simulateUserInitiatedFeedReload()
        XCTAssertTrue(sut.isShowingLoadingIndicator(), "Expected visible after initiating a load")
        
        loader.completeFeedLoading(at: 1)
        XCTAssertFalse(sut.isShowingLoadingIndicator(), "Expected hidden after the loading is completed")
        
        sut.simulateAppearance()
        XCTAssertFalse(sut.isShowingLoadingIndicator(), "Expected hidden after view is appeared on second+ time")
        
        sut.simulateUserInitiatedFeedReload()
        loader.completeFeedLoadingWithError(at: 2)
        XCTAssertFalse(sut.isShowingLoadingIndicator(), "Expected hidden after the loading is completed with an error")
    }
    
    override func test_loadFeedCompletion_rendersSuccessfullyLoadedFeed() {
        let image0 = makeImage(description: "a description", location: "a location")
        let image1 = makeImage(description: nil, location: "another location")
        let image2 = makeImage(description: "another description", location: nil)
        let image3 = makeImage(description: nil, location: nil)
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        assertThat(sut, isRendering: [])
        
        loader.completeFeedLoading(with: [image0], at: .zero)
        assertThat(sut, isRendering: [image0])
        
        sut.simulateUserInitiatedFeedReload()
        loader.completeFeedLoading(with: [image0, image1, image2, image3], at: 1)
        assertThat(sut, isRendering: [image0, image1, image2, image3])
    }
    
    override func test_loadFeedCompletion_rendersSuccessfullyLoadedEmptyFeedAfterNonEmptyFeed() {
        let image0 = makeImage()
        let image1 = makeImage()
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        assertThat(sut, isRendering: [])
        
        loader.completeFeedLoading(with: [image0, image1], at: .zero)
        assertThat(sut, isRendering: [image0, image1])
        
        sut.simulateUserInitiatedFeedReload()
        loader.completeFeedLoading(with: [], at: 1)
        assertThat(sut, isRendering: [])
    }
    
    override func test_loadFeedCompletion_doesNotAlterCurrentRenderingStateOnError() {
        let image0 = makeImage()
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [image0], at: .zero)
        assertThat(sut, isRendering: [image0])
        
        sut.simulateUserInitiatedFeedReload()
        loader.completeFeedLoadingWithError(at: 1)
        assertThat(sut, isRendering: [image0])
    }
    
    override func test_loadFeedCompletion_dispatchesFromBackgroundToMainThread() {
        let (sut, loader) = makeSUT()
        sut.simulateAppearance()
        
        let exp = expectation(description: "Wait for the feed loading completion")
        DispatchQueue.global().async { [weak loader] in
            loader?.completeFeedLoading()
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
    }
    
    override func test_loadFeedCompletion_rendersErrorMessageOnErrorUntilNextReload() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        XCTAssertEqual(sut.errorMessage, nil)
        
        loader.completeFeedLoadingWithError()
        XCTAssertEqual(sut.errorMessage, loadError)
        
        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(sut.errorMessage, nil)
    }
    
    override func test_tapOnErrorView_hidesErrorMessage() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoadingWithError()
        XCTAssertEqual(sut.errorMessage, loadError)
        
        sut.simulateTapOnErrorMessage()
        XCTAssertEqual(sut.errorMessage, nil)
    }
    
    override func test_errorView_dismissesErrorMessageOnTap() {
        let (sut, loader) = makeSUT()

        sut.simulateAppearance()
        XCTAssertEqual(sut.errorMessage, nil)

        loader.completeFeedLoadingWithError(at: 0)
        XCTAssertEqual(sut.errorMessage, loadError)

        sut.simulateTapOnErrorMessage()
        XCTAssertEqual(sut.errorMessage, nil)
    }
    
    // MARK: Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: ListViewController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = CommentsUIComposer.feedComposedWith(feedLoader: loader.loadPublisher)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }
    
    private func makeImage(
        description: String? = nil,
        location: String? = nil,
        url: URL = URL(string: "http://any-url.com)")!
    ) -> FeedImage {
        return FeedImage(id: UUID(), description: description, location: location, url: url)
    }
    
    private func assertThat(
        _ sut: ListViewController,
        isRendering feed: [FeedImage],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        sut.view.enforceLayoutCycle()
        
        guard sut.numberOfRenderedFeedImageViews() == feed.count else {
            return XCTFail(
                "Expected \(feed.count) images, got \(sut.numberOfRenderedFeedImageViews()) instead",
                file: file,
                line: line
            )
        }
        
        XCTAssertEqual(
            sut.numberOfRenderedFeedImageViews(),
            feed.count,
            "Expected \(feed.count) image, got \(sut.numberOfRenderedFeedImageViews()) instead",
            file: file,
            line: line
        )
        feed.enumerated().forEach { index, image in
            assertThat(sut, hasConfiguredFor: image, at: index, file: file, line: line)
        }
        
        executeRunLoopToCleanUpReferences()
    }
    
    private func assertThat(
        _ sut: ListViewController,
        hasConfiguredFor image: FeedImage,
        at index: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let shouldLocationBeVisible = image.location != nil
        let view = sut.feedImageView(at: index)
        XCTAssertEqual(
            view?.isShowingLocation,
            shouldLocationBeVisible,
            "Expected `isShowingLocation` to be \(shouldLocationBeVisible) for index at \(index)",
            file: file,
            line: line
        )
        XCTAssertEqual(
            view?.locationText,
            image.location,
            "Expected `locationText` to be \(image.location as Any) for index at \(index)",
            file: file,
            line: line
        )
        XCTAssertEqual(
            view?.descriptionText,
            image.description,
            "Expected `descriptionText` to be \(image.description as Any) for index at \(index)",
            file: file,
            line: line
        )
    }
}

// swiftlint:enable force_unwrapping
