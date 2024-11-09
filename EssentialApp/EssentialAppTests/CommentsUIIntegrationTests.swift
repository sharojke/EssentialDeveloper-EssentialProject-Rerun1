import Combine
import EssentialApp
import EssentialFeed
import EssentialFeediOS
import UIKit
import XCTest

private final class LoaderSpy {
    typealias Publisher = AnyPublisher<[ImageComment], Error>
    
    private final class TaskSpy: FeedImageDataLoaderTask {
        private let onCancel: () -> Void
        
        init(onCancel: @escaping () -> Void) {
            self.onCancel = onCancel
        }
        
        func cancel() {
            onCancel()
        }
    }
    
    private var requests = [PassthroughSubject<[ImageComment], Error>]()
    
    var loadCallCount: Int {
        return requests.count
    }
    
    func loadPublisher() -> Publisher {
        let publisher = PassthroughSubject<[ImageComment], Error>()
        requests.append(publisher)
        return publisher.eraseToAnyPublisher()
    }
    
    func completeLoading(with comments: [ImageComment] = [], at index: Int = .zero) {
        requests[index].send(comments)
    }
    
    func completeLoadingWithError(at index: Int = .zero) {
        requests[index].send(completion: .failure(anyNSError()))
    }
}

final class CommentsUIIntegrationTests: XCTestCase {
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
    
    func test_loadCommentsCompletion_rendersSuccessfullyLoadedComments() {
        let comment0 = makeComment(message: "mo0", username: "u0")
        let comment1 = makeComment(message: "mo1", username: "u1")
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        assertThat(sut, isRendering: [])
        
        loader.completeLoading(with: [comment0], at: .zero)
        assertThat(sut, isRendering: [comment0])
        
        sut.simulateUserInitiatedReload()
        loader.completeLoading(with: [comment0, comment1], at: 1)
        assertThat(sut, isRendering: [comment0, comment1])
    }
    
    func test_loadCommentsCompletion_rendersSuccessfullyLoadedEmptyCommentsAfterNonEmptyComments() {
        let comment0 = makeComment()
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        assertThat(sut, isRendering: [])
        
        loader.completeLoading(with: [comment0], at: .zero)
        assertThat(sut, isRendering: [comment0])
        
        sut.simulateUserInitiatedReload()
        loader.completeLoading(with: [], at: 1)
        assertThat(sut, isRendering: [])
    }
    
    func test_loadCommentsCompletion_doesNotAlterCurrentRenderingStateOnError() {
        let comment0 = makeComment()
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeLoading(with: [comment0], at: .zero)
        assertThat(sut, isRendering: [comment0])
        
        sut.simulateUserInitiatedReload()
        loader.completeLoadingWithError(at: 1)
        assertThat(sut, isRendering: [comment0])
    }
    
    func test_loadCommentsCompletion_dispatchesFromBackgroundToMainThread() {
        let (sut, loader) = makeSUT()
        sut.simulateAppearance()
        
        let exp = expectation(description: "Wait for the feed loading completion")
        DispatchQueue.global().async { [weak loader] in
            loader?.completeLoading()
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
    }
    
    func test_loadCommentsCompletion_rendersErrorMessageOnErrorUntilNextReload() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        XCTAssertEqual(sut.errorMessage, nil)
        
        loader.completeLoadingWithError()
        XCTAssertEqual(sut.errorMessage, loadError)
        
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(sut.errorMessage, nil)
    }
    
    func test_tapOnErrorView_hidesErrorMessage() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeLoadingWithError()
        XCTAssertEqual(sut.errorMessage, loadError)
        
        sut.simulateTapOnErrorMessage()
        XCTAssertEqual(sut.errorMessage, nil)
    }
    
    func test_errorView_dismissesErrorMessageOnTap() {
        let (sut, loader) = makeSUT()

        sut.simulateAppearance()
        XCTAssertEqual(sut.errorMessage, nil)

        loader.completeLoadingWithError(at: 0)
        XCTAssertEqual(sut.errorMessage, loadError)

        sut.simulateTapOnErrorMessage()
        XCTAssertEqual(sut.errorMessage, nil)
    }
    
    func test_deinit_cancelsRunningRequest() {
        var cancelCallCount = Int.zero
        var sut: ListViewController?
        
        autoreleasepool {
            sut = CommentsUIComposer.commentsComposedWith {
                PassthroughSubject<[ImageComment], Error>()
                    .handleEvents(receiveCancel: {
                        cancelCallCount += 1
                    })
                    .eraseToAnyPublisher()
            }
        }
        
        sut?.simulateAppearance()
        XCTAssertEqual(cancelCallCount, .zero)
        
        sut = nil
        XCTAssertEqual(cancelCallCount, 1)
    }
    
    // MARK: Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: ListViewController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = CommentsUIComposer.commentsComposedWith(commentsLoader: loader.loadPublisher)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }
    
    private func makeComment(
        message: String = "any message",
        username: String = "any username"
    ) -> ImageComment {
        return ImageComment(
            id: UUID(),
            message: message,
            createdAt: Date(),
            username: username
        )
    }
    
    private func assertThat(
        _ sut: ListViewController,
        isRendering comments: [ImageComment],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        sut.view.enforceLayoutCycle()
        
        guard sut.numberOfRenderedFeedImageViews() == comments.count else {
            return XCTFail(
                "Expected \(comments.count) comments, got \(sut.numberOfRenderedCommentsViews()) instead",
                file: file,
                line: line
            )
        }
        
        XCTAssertEqual(
            sut.numberOfRenderedCommentsViews(),
            comments.count,
            "Expected \(comments.count) comments, got \(sut.numberOfRenderedCommentsViews()) instead",
            file: file,
            line: line
        )
        let viewModel = ImageCommentsPresenter.map(comments)
        viewModel.comments.enumerated().forEach { index, comment in
            XCTAssertEqual(sut.commentMessage(at: index), comment.message, "Message at \(index)", file: file, line: line)
            XCTAssertEqual(sut.commentDate(at: index), comment.date, "Date at \(index)", file: file, line: line)
            XCTAssertEqual(sut.commentUsername(at: index), comment.username, "Username at \(index)", file: file, line: line)
        }
        
        executeRunLoopToCleanUpReferences()
    }
}
