import Combine
import EssentialApp
import EssentialFeed
import EssentialFeediOS
import UIKit
import XCTest

// swiftlint:disable force_unwrapping

private final class LoaderSpy {
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
    
    private var requests = [PassthroughSubject<[FeedImage], Error>]()
    
    var loadCallCount: Int {
        return requests.count
    }
    
    func loadPublisher() -> Publisher {
        let publisher = PassthroughSubject<[FeedImage], Error>()
        requests.append(publisher)
        return publisher.eraseToAnyPublisher()
    }
    
    func completeLoading(with feed: [FeedImage] = [], at index: Int = .zero) {
        requests[index].send(feed)
    }
    
    func completeLoadingWithError(at index: Int = .zero) {
        requests[index].send(completion: .failure(anyNSError()))
    }
}

final class CommentsUIIntegrationTests: FeedUIIntegrationTests {
    func test_commentsView_hasTitle() {
        let (sut, _) = makeSUT()
        
        sut.simulateAppearance()
        
        XCTAssertEqual(sut.title, commentsTitle)
    }
    
    func test_loadCommentsActions_runsAutomaticallyOnlyOnFirstAppearance() {
        let (sut, loader) = makeSUT()
        XCTAssertEqual(loader.loadCallCount, 0, "Expected no loading requests before view appears")
        
        sut.simulateAppearance()
        XCTAssertEqual(loader.loadCallCount, 1, "Expected a loading request once view appears")
        
        sut.simulateAppearance()
        XCTAssertEqual(loader.loadCallCount, 1, "Expected no loading request the second time view appears")
    }
    
    func test_loadCommentsActions_requestCommentsFromLoader() {
        let (sut, loader) = makeSUT()
        XCTAssertEqual(loader.loadCallCount, .zero, "Expected no requests before view is appeared")
        
        sut.simulateAppearance()
        XCTAssertEqual(loader.loadCallCount, 1, "Expected a request after view is appeared")
        
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(loader.loadCallCount, 2, "Expected another request after initiating a load")
        
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(loader.loadCallCount, 3, "Expected another request after initiating another load")
    }
    
    func test_loadingFeedIndicator_isVisibleWhileLoadingComments() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        XCTAssertTrue(sut.isShowingLoadingIndicator(), "Expected visible after view is appeared")
        
        loader.completeLoading(at: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator(), "Expected hidden after the loading is completed successfully")
        
        sut.simulateUserInitiatedReload()
        XCTAssertTrue(sut.isShowingLoadingIndicator(), "Expected visible after initiating a load")
        
        loader.completeLoading(at: 1)
        XCTAssertFalse(sut.isShowingLoadingIndicator(), "Expected hidden after the loading is completed")
        
        sut.simulateAppearance()
        XCTAssertFalse(sut.isShowingLoadingIndicator(), "Expected hidden after view is appeared on second+ time")
        
        sut.simulateUserInitiatedReload()
        loader.completeLoadingWithError(at: 2)
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
        
        loader.completeLoading(with: [image0], at: .zero)
        assertThat(sut, isRendering: [image0])
        
        sut.simulateUserInitiatedReload()
        loader.completeLoading(with: [image0, image1, image2, image3], at: 1)
        assertThat(sut, isRendering: [image0, image1, image2, image3])
    }
    
    override func test_loadFeedCompletion_rendersSuccessfullyLoadedEmptyFeedAfterNonEmptyFeed() {
        let image0 = makeImage()
        let image1 = makeImage()
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        assertThat(sut, isRendering: [])
        
        loader.completeLoading(with: [image0, image1], at: .zero)
        assertThat(sut, isRendering: [image0, image1])
        
        sut.simulateUserInitiatedReload()
        loader.completeLoading(with: [], at: 1)
        assertThat(sut, isRendering: [])
    }
    
    override func test_loadFeedCompletion_doesNotAlterCurrentRenderingStateOnError() {
        let image0 = makeImage()
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeLoading(with: [image0], at: .zero)
        assertThat(sut, isRendering: [image0])
        
        sut.simulateUserInitiatedReload()
        loader.completeLoadingWithError(at: 1)
        assertThat(sut, isRendering: [image0])
    }
    
    override func test_loadFeedCompletion_dispatchesFromBackgroundToMainThread() {
        let (sut, loader) = makeSUT()
        sut.simulateAppearance()
        
        let exp = expectation(description: "Wait for the feed loading completion")
        DispatchQueue.global().async { [weak loader] in
            loader?.completeLoading()
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
    }
    
    override func test_loadFeedCompletion_rendersErrorMessageOnErrorUntilNextReload() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        XCTAssertEqual(sut.errorMessage, nil)
        
        loader.completeLoadingWithError()
        XCTAssertEqual(sut.errorMessage, loadError)
        
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(sut.errorMessage, nil)
    }
    
    override func test_tapOnErrorView_hidesErrorMessage() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeLoadingWithError()
        XCTAssertEqual(sut.errorMessage, loadError)
        
        sut.simulateTapOnErrorMessage()
        XCTAssertEqual(sut.errorMessage, nil)
    }
    
    override func test_errorView_dismissesErrorMessageOnTap() {
        let (sut, loader) = makeSUT()

        sut.simulateAppearance()
        XCTAssertEqual(sut.errorMessage, nil)

        loader.completeLoadingWithError(at: 0)
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
