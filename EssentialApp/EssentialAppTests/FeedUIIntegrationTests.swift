import Combine
import EssentialApp
import EssentialFeed
import EssentialFeediOS
import UIKit
import XCTest

// swiftlint:disable file_length
// swiftlint:disable force_unwrapping
// swiftlint:disable type_body_length

private final class LoaderSpy: FeedImageDataLoader {
    typealias Publisher = AnyPublisher<Paginated<FeedImage>, Error>
    
    private final class TaskSpy: FeedImageDataLoaderTask {
        private let onCancel: () -> Void
        
        init(onCancel: @escaping () -> Void) {
            self.onCancel = onCancel
        }
        
        func cancel() {
            onCancel()
        }
    }
    
    private var feedRequests = [PassthroughSubject<Paginated<FeedImage>, Error>]()
    private var imageRequests = [(url: URL, completion: LoadImageResultCompletion)]()
    private var loadMoreRequests = [PassthroughSubject<Paginated<FeedImage>, Error>]()
    private(set) var cancelledImageURLs = [URL]()
    
    var loadedImageURLs: [URL] {
        return imageRequests.map(\.url)
    }
    
    var loadFeedCallCount: Int {
        return feedRequests.count
    }
    
    var loadMoreCallCount: Int {
        return loadMoreRequests.count
    }
    
    func loadPublisher() -> Publisher {
        let publisher = PassthroughSubject<Paginated<FeedImage>, Error>()
        feedRequests.append(publisher)
        return publisher.eraseToAnyPublisher()
    }
    
    func completeFeedLoading(with feed: [FeedImage] = [], at index: Int = .zero) {
        feedRequests[index].send(Paginated(items: feed, loadMorePublisher: { [weak self] in
            let publisher = PassthroughSubject<Paginated<FeedImage>, Error>()
            self?.loadMoreRequests.append(publisher)
            return publisher.eraseToAnyPublisher()
        }))
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
    
    func completeLoadMore(with feed: [FeedImage] = [], lastPage: Bool = false, at index: Int = .zero) {
        loadMoreRequests[index].send(
            Paginated(
                items: feed,
                loadMorePublisher: lastPage ? nil : { [weak self] in
                    let publisher = PassthroughSubject<Paginated<FeedImage>, Error>()
                    self?.loadMoreRequests.append(publisher)
                    return publisher.eraseToAnyPublisher()
                }
            )
        )
    }
    
    func completeLoadMoreWithError(at index: Int = .zero) {
        loadMoreRequests[index].send(completion: .failure(anyNSError()))
    }
}

final class FeedUIIntegrationTests: XCTestCase {
    func test_feedView_hasTitle() {
        let (sut, _) = makeSUT()
        
        sut.simulateAppearance()
        
        XCTAssertEqual(sut.title, feedTitle)
    }
    
    func test_imageSelection_notifiesHandler() {
        let image0 = makeImage()
        let image1 = makeImage()
        var selectedImages = [FeedImage]()
        let (sut, loader) = makeSUT { selectedImages.append($0) }
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [image0, image1])
        
        sut.simulateTapOnFeedImage(at: .zero)
        XCTAssertEqual(selectedImages, [image0])
        
        sut.simulateTapOnFeedImage(at: 1)
        XCTAssertEqual(selectedImages, [image0, image1])
    }
    
    func test_loadFeedActions_runsAutomaticallyOnlyOnFirstAppearance() {
        let (sut, loader) = makeSUT()
        XCTAssertEqual(loader.loadFeedCallCount, 0, "Expected no loading requests before view appears")
        
        sut.simulateAppearance()
        XCTAssertEqual(loader.loadFeedCallCount, 1, "Expected a loading request once view appears")
        
        sut.simulateAppearance()
        XCTAssertEqual(loader.loadFeedCallCount, 1, "Expected no loading request the second time view appears")
    }
    
    func test_loadFeedActions_requestFeedFromLoader() {
        let (sut, loader) = makeSUT()
        XCTAssertEqual(loader.loadFeedCallCount, .zero, "Expected no requests before view is appeared")
        
        sut.simulateAppearance()
        XCTAssertEqual(loader.loadFeedCallCount, 1, "Expected a request after view is appeared")
        
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(loader.loadFeedCallCount, 2, "Expected another request after initiating a load")
        
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(loader.loadFeedCallCount, 3, "Expected another request after initiating another load")
    }
    
    func test_loadingFeedIndicator_isVisibleWhileLoadingFeed() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        XCTAssertTrue(sut.isShowingLoadingIndicator(), "Expected visible after view is appeared")
        
        loader.completeFeedLoading(at: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator(), "Expected hidden after the loading is completed successfully")
        
        sut.simulateUserInitiatedReload()
        XCTAssertTrue(sut.isShowingLoadingIndicator(), "Expected visible after initiating a load")
        
        loader.completeFeedLoading(at: 1)
        XCTAssertFalse(sut.isShowingLoadingIndicator(), "Expected hidden after the loading is completed")
        
        sut.simulateAppearance()
        XCTAssertFalse(sut.isShowingLoadingIndicator(), "Expected hidden after view is appeared on second+ time")
        
        sut.simulateUserInitiatedReload()
        loader.completeFeedLoadingWithError(at: 2)
        XCTAssertFalse(sut.isShowingLoadingIndicator(), "Expected hidden after the loading is completed with an error")
    }
    
    func test_loadFeedCompletion_rendersSuccessfullyLoadedFeed() {
        let image0 = makeImage(description: "a description", location: "a location")
        let image1 = makeImage(description: nil, location: "another location")
        let image2 = makeImage(description: "another description", location: nil)
        let image3 = makeImage(description: nil, location: nil)
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        assertThat(sut, isRendering: [])
        
        loader.completeFeedLoading(with: [image0, image1], at: .zero)
        assertThat(sut, isRendering: [image0, image1])
        
        sut.simulateLoadMoreFeedAction()
        loader.completeLoadMore(with: [image0, image1, image2, image3])
        assertThat(sut, isRendering: [image0, image1, image2, image3])
        
        sut.simulateUserInitiatedReload()
        loader.completeFeedLoading(with: [image0, image1], at: 1)
        assertThat(sut, isRendering: [image0, image1])
    }
    
    func test_loadFeedCompletion_rendersSuccessfullyLoadedEmptyFeedAfterNonEmptyFeed() {
        let image0 = makeImage()
        let image1 = makeImage()
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        assertThat(sut, isRendering: [])
        
        loader.completeFeedLoading(with: [image0], at: .zero)
        assertThat(sut, isRendering: [image0])
        
        sut.simulateLoadMoreFeedAction()
        loader.completeLoadMore(with: [image0, image1])
        assertThat(sut, isRendering: [image0, image1])
        
        sut.simulateUserInitiatedReload()
        loader.completeFeedLoading(with: [], at: 1)
        assertThat(sut, isRendering: [])
    }
    
    func test_loadFeedCompletion_doesNotAlterCurrentRenderingStateOnError() {
        let image0 = makeImage()
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [image0], at: .zero)
        assertThat(sut, isRendering: [image0])
        
        sut.simulateUserInitiatedReload()
        loader.completeFeedLoadingWithError(at: 1)
        assertThat(sut, isRendering: [image0])
        
        sut.simulateLoadMoreFeedAction()
        loader.completeLoadMoreWithError()
        assertThat(sut, isRendering: [image0])
    }
    
    func test_loadFeedCompletion_dispatchesFromBackgroundToMainThread() {
        let (sut, loader) = makeSUT()
        sut.simulateAppearance()
        
        let exp = expectation(description: "Wait for the feed loading completion")
        DispatchQueue.global().async { [weak loader] in
            loader?.completeFeedLoading()
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
    }
    
    func test_feedImageView_loadsImageURLWhenVisible() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [image0, image1], at: .zero)
        XCTAssertEqual(loader.loadedImageURLs, [], "Expected no image URL requests until views become visible")
        
        sut.simulateFeedImageViewVisible(at: .zero)
        XCTAssertEqual(
            loader.loadedImageURLs,
            [image0.url],
            "Expected first image URL request once first view becomes visible"
        )
        
        sut.simulateFeedImageViewVisible(at: 1)
        XCTAssertEqual(
            loader.loadedImageURLs,
            [image0.url, image1.url],
            "Expected second image URL request once second view becomes visible"
        )
    }
    
    func test_feedImageView_reloadsImageURLWhenBecomingVisibleAgain() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [image0, image1])
        
        sut.simulateFeedImageBecomingVisibleAgain(at: 0)
        XCTAssertEqual(
            loader.loadedImageURLs,
            [image0.url, image0.url],
            "Expected two image URL request after first view becomes visible again"
        )
        
        sut.simulateFeedImageBecomingVisibleAgain(at: 1)
        XCTAssertEqual(
            loader.loadedImageURLs,
            [image0.url, image0.url, image1.url, image1.url],
            "Expected two new image URL request after second view becomes visible again"
        )
    }
    
    func test_feedImageView_cancelsImageLoadingWhenNotVisibleAnymore() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [image0, image1], at: .zero)
        XCTAssertEqual(
            loader.cancelledImageURLs,
            [],
            "Expected no cancelled image URL requests until views become visible"
        )
        
        sut.simulateFeedImageViewNotVisible(at: .zero)
        XCTAssertEqual(
            loader.cancelledImageURLs,
            [image0.url],
            "Expected one cancelled image URL request once first view becomes not visible"
        )
        
        sut.simulateFeedImageViewNotVisible(at: 1)
        XCTAssertEqual(
            loader.cancelledImageURLs,
            [image0.url, image1.url],
            "Expected two cancelled image URL request once first view becomes not visible"
        )
    }
    
    func test_feedImageViewLoadingIndicator_isVisibleWhileLoadingImage() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [makeImage(), makeImage()])
        
        let view0 = sut.simulateFeedImageViewVisible(at: .zero)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)
        XCTAssertEqual(
            view0?.isShowingImageLoadingIndicator,
            true,
            "Expected loading indicator for the first view while loading the first image"
        )
        XCTAssertEqual(
            view1?.isShowingImageLoadingIndicator,
            true,
            "Expected loading indicator for the second view while loading the second image"
        )
        
        loader.completeImageLoading(at: .zero)
        XCTAssertEqual(
            view0?.isShowingImageLoadingIndicator,
            false,
            "Expected no loading indicator for the first view after the first image is loaded"
        )
        XCTAssertEqual(
            view1?.isShowingImageLoadingIndicator,
            true,
            "Expected loading indicator for the second view after the first image is loaded"
        )
        
        loader.completeImageLoading(at: 1)
        XCTAssertEqual(
            view0?.isShowingImageLoadingIndicator,
            false,
            "Expected no loading indicator for the first view after the second image is loaded"
        )
        XCTAssertEqual(
            view1?.isShowingImageLoadingIndicator,
            false,
            "Expected no loading indicator for the second view after the second image is loaded"
        )
    }
    
    func test_feedImageView_rendersImageLoadedFromURL() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [makeImage(), makeImage()])
        
        let view0 = sut.simulateFeedImageViewVisible(at: .zero)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)
        XCTAssertEqual(
            view0?.renderedImage,
            nil,
            "Expected no image for the first view while loading the first image"
        )
        XCTAssertEqual(
            view1?.renderedImage,
            nil,
            "Expected no image for the second view while loading the second image"
        )
        
        let imageData0 = UIImage.make(withColor: .green).pngData()!
        loader.completeImageLoading(with: imageData0, at: .zero)
        XCTAssertEqual(
            view0?.renderedImage,
            imageData0,
            "Expected image for the first view after the first image is loaded"
        )
        XCTAssertEqual(
            view1?.renderedImage,
            nil,
            "Expected no image for the second view after the first image is loaded"
        )
        
        let imageData1 = UIImage.make(withColor: .red).pngData()!
        loader.completeImageLoading(with: imageData1, at: 1)
        XCTAssertEqual(
            view0?.renderedImage,
            imageData0,
            "Expected no image change for the first view after the second image is loaded"
        )
        XCTAssertEqual(
            view1?.renderedImage,
            imageData1,
            "Expected image for the second view after the second image is loaded"
        )
    }
    
    func test_feedImageViewRetryButton_isVisibleOnImageURLLoadError() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [makeImage(), makeImage()])
        
        let view0 = sut.simulateFeedImageViewVisible(at: .zero)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)
        XCTAssertEqual(
            view0?.isShowingRetryAction,
            false,
            "Expected no retry for the first view while loading the first image"
        )
        XCTAssertEqual(
            view1?.isShowingRetryAction,
            false,
            "Expected no retry for the second view while loading the second image"
        )
        
        loader.completeImageLoadingWithError(at: .zero)
        XCTAssertEqual(
            view0?.isShowingRetryAction,
            true,
            "Expected retry for the first view after loading the first image fails"
        )
        XCTAssertEqual(
            view1?.isShowingRetryAction,
            false,
            "Expected no retry for the second view after loading the first image fails"
        )
        
        loader.completeImageLoadingWithError(at: 1)
        XCTAssertEqual(
            view0?.isShowingRetryAction,
            true,
            "Expected no retry change for the first view after loading the second image fails"
        )
        XCTAssertEqual(
            view1?.isShowingRetryAction,
            true,
            "Expected retry for the second view after loading the second image fails"
        )
    }
    
    func test_feedImageViewRetryButton_isVisibleOnInvalidImageData() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [makeImage()])
        
        let view = sut.simulateFeedImageViewVisible(at: .zero)
        let invalidData = Data("invalid data".utf8)
        loader.completeImageLoading(with: invalidData)
        
        XCTAssertEqual(
            view?.isShowingRetryAction,
            true,
            "Expected retry when invalid image data"
        )
    }
    
    func test_feedImageViewRetryAction_retriesImageLoad() {
        let image0 = makeImage(url: URL(string: "http://first-url.com")!)
        let image1 = makeImage(url: URL(string: "http://second-url.com")!)
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [image0, image1])
        
        let view0 = sut.simulateFeedImageViewVisible(at: .zero)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)
        XCTAssertEqual(
            loader.loadedImageURLs,
            [image0.url, image1.url],
            "Expected two image URLs for the two visible views"
        )
        
        loader.completeImageLoadingWithError(at: .zero)
        loader.completeImageLoadingWithError(at: 1)
        XCTAssertEqual(
            loader.loadedImageURLs,
            [image0.url, image1.url],
            "Expected two image URLs before retry action"
        )
        
        view0?.simulateRetryAction()
        XCTAssertEqual(
            loader.loadedImageURLs,
            [image0.url, image1.url, image0.url],
            "Expected three image URLs after retry action for the first view"
        )
        
        view1?.simulateRetryAction()
        XCTAssertEqual(
            loader.loadedImageURLs,
            [image0.url, image1.url, image0.url, image1.url],
            "Expected four image URLs after retry action for the second view"
        )
    }
    
    func test_feedImageView_preloadsImageURLWhenNearVisible() {
        let image0 = makeImage(url: URL(string: "http://first-url.com")!)
        let image1 = makeImage(url: URL(string: "http://second-url.com")!)
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [image0, image1])
        XCTAssertEqual(
            loader.loadedImageURLs,
            [],
            "Expected no image URLs before near visible"
        )
        
        sut.simulateFeedImageViewNearVisible(at: .zero)
        XCTAssertEqual(
            loader.loadedImageURLs,
            [image0.url],
            "Expected the first image URL after the first view is near visible"
        )
        
        sut.simulateFeedImageViewNearVisible(at: 1)
        XCTAssertEqual(
            loader.loadedImageURLs,
            [image0.url, image1.url],
            "Expected two image URLs after the second view is near visible"
        )
    }
    
    func test_feedImageView_cancelsImageURLPreloadingWhenNotNearVisibleAnymore() {
        let image0 = makeImage(url: URL(string: "http://first-url.com")!)
        let image1 = makeImage(url: URL(string: "http://second-url.com")!)
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [image0, image1])
        XCTAssertEqual(
            loader.loadedImageURLs,
            [],
            "Expected no image URLs before near visible"
        )
        
        sut.simulateFeedImageViewNotNearVisible(at: .zero)
        XCTAssertEqual(
            loader.cancelledImageURLs,
            [image0.url],
            "Expected the first image URL is canceled after the first view is not near visible"
        )
        
        sut.simulateFeedImageViewNotNearVisible(at: 1)
        XCTAssertEqual(
            loader.cancelledImageURLs,
            [image0.url, image1.url],
            "Expected two image URLs are canceled after the second view is not near visible"
        )
    }
    
    func test_feedImageView_doesNotRenderLoadedImageWhenNoVisibleAnymore() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [makeImage()])
        
        let view0 = sut.simulateFeedImageViewNotVisible(at: .zero)
        loader.completeImageLoading(with: anyImageData(), at: .zero)
        
        XCTAssertEqual(
            view0?.renderedImage,
            nil,
            "Expected no renderedImage when view is not visible"
        )
    }
    
    func test_feedImageView_doesNotShowDataFromPreviousRequestWhenCellIsReused() throws {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [makeImage(), makeImage()])
        
        let view0 = sut.simulateFeedImageViewVisible(at: .zero)
        view0?.prepareForReuse()
        
        let imageData0 = anyImageData()
        loader.completeImageLoading(with: imageData0, at: .zero)
        
        XCTAssertEqual(
            view0?.renderedImage,
            nil,
            "Expected no image state change for reused view once image loading completes successfully"
        )
    }
    
    func test_feedImageView_showsDataForNewViewRequestAfterPreviousViewIsReused() throws {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [makeImage()])
        
        let previousView = sut.simulateFeedImageViewNotVisible(at: 0)
        let newView = sut.simulateFeedImageViewVisible(at: 0)
        previousView?.prepareForReuse()
        
        let imageData = anyImageData()
        loader.completeImageLoading(with: imageData, at: 1)
        
        XCTAssertEqual(newView?.renderedImage, imageData)
    }
    
    // TODO: Make this test pass
//    func test_feedImageView_configuresViewCorrectlyWhenTransitioningFromNearVisibleToVisibleWhileStillPreloadingImage() {
//        let (sut, loader) = makeSUT()
//        
//        sut.simulateAppearance()
//        loader.completeFeedLoading(with: [makeImage()])
//        
//        sut.simulateFeedImageViewNearVisible(at: 0)
//        let view0 = sut.simulateFeedImageViewVisible(at: 0)
//        XCTAssertEqual(
//            view0?.renderedImage,
//            nil,
//            "Expected no rendered image when view becomes visible while still preloading image"
//        )
//        XCTAssertEqual(
//            view0?.isShowingRetryAction,
//            false,
//            "Expected no retry action when view becomes visible while still preloading image"
//        )
//        XCTAssertEqual(
//            view0?.isShowingImageLoadingIndicator,
//            true,
//            "Expected loading indicator when view becomes visible while still preloading image"
//        )
//        
//        let imageData = UIImage.make(withColor: .red).pngData()!
//        loader.completeImageLoading(with: imageData, at: 0)
//        
//        XCTAssertEqual(
//            view0?.renderedImage,
//            imageData,
//            "Expected rendered image after image preloads successfully"
//        )
//        XCTAssertEqual(
//            view0?.isShowingRetryAction,
//            false,
//            "Expected no retry action after image preloads successfully"
//        )
//        XCTAssertEqual(
//            view0?.isShowingImageLoadingIndicator,
//            false,
//            "Expected no loading indicator after image preloads successfully"
//        )
//    }
    
    func test_feedImageView_configuresViewCorrectlyWhenCellBecomingVisibleAgain() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [makeImage()])
        
        let view0 = sut.simulateFeedImageBecomingVisibleAgain(at: 0)
        XCTAssertEqual(
            view0?.renderedImage,
            nil,
            "Expected no rendered image when view becomes visible again"
        )
        XCTAssertEqual(
            view0?.isShowingRetryAction,
            false,
            "Expected no retry action when view becomes visible again"
        )
        XCTAssertEqual(
            view0?.isShowingImageLoadingIndicator,
            true,
            "Expected loading indicator when view becomes visible again"
        )
        
        let imageData = UIImage.make(withColor: .red).pngData()!
        loader.completeImageLoading(with: imageData, at: 1)
        XCTAssertEqual(
            view0?.renderedImage,
            imageData,
            "Expected rendered image when image loads successfully after view becomes visible again"
        )
        XCTAssertEqual(
            view0?.isShowingRetryAction,
            false,
            "Expected no retry when image loads successfully after view becomes visible again"
        )
        XCTAssertEqual(
            view0?.isShowingImageLoadingIndicator,
            false,
            "Expected no loading indicator when image loads successfully after view becomes visible again"
        )
    }
    
    func test_loadImageDataCompletion_dispatchesFromBackgroundToMainThread() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [makeImage()])
        _ = sut.simulateFeedImageViewVisible(at: .zero)
        
        let imageData = anyImageData()
        let exp = expectation(description: "Wait for the image data loading completion")
        DispatchQueue.global().async { [weak loader] in
            loader?.completeImageLoading(with: imageData, at: .zero)
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
    }
    
    func test_loadFeedCompletion_rendersErrorMessageOnErrorUntilNextReload() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        XCTAssertEqual(sut.errorMessage, nil)
        
        loader.completeFeedLoadingWithError()
        XCTAssertEqual(sut.errorMessage, loadError)
        
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(sut.errorMessage, nil)
    }
    
    func test_loadMoreCompletion_rendersErrorMessageOnError() {
        let (sut, loader) = makeSUT()
        sut.simulateAppearance()
        loader.completeFeedLoading()
        
        sut.simulateLoadMoreFeedAction()
        XCTAssertEqual(sut.loadMoreFeedErrorMessage, nil)
        
        loader.completeLoadMoreWithError()
        XCTAssertEqual(sut.loadMoreFeedErrorMessage, loadError)
        
        sut.simulateLoadMoreFeedAction()
        XCTAssertEqual(sut.loadMoreFeedErrorMessage, nil)
    }
    
    func test_tapOnErrorView_hidesErrorMessage() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoadingWithError()
        XCTAssertEqual(sut.errorMessage, loadError)
        
        sut.simulateTapOnErrorMessage()
        XCTAssertEqual(sut.errorMessage, nil)
    }
    
    func test_tapOnLoadMoreErrorView_loadsMore() {
        let (sut, loader) = makeSUT()
        sut.simulateAppearance()
        loader.completeFeedLoading()
        
        sut.simulateLoadMoreFeedAction()
        XCTAssertEqual(loader.loadMoreCallCount, 1)
                
        sut.simulateTapOnLoadMoreFeedError()
        XCTAssertEqual(loader.loadMoreCallCount, 1)
        
        loader.completeLoadMoreWithError()
        sut.simulateTapOnLoadMoreFeedError()
        XCTAssertEqual(loader.loadMoreCallCount, 2)
    }
    
    func test_errorView_dismissesErrorMessageOnTap() {
        let (sut, loader) = makeSUT()

        sut.simulateAppearance()
        XCTAssertEqual(sut.errorMessage, nil)

        loader.completeFeedLoadingWithError(at: 0)
        XCTAssertEqual(sut.errorMessage, loadError)

        sut.simulateTapOnErrorMessage()
        XCTAssertEqual(sut.errorMessage, nil)
    }
    
    // MARK: Load More Tests
    
    func test_loadMoreActions_requestMoreFromLoader() {
        let (sut, loader) = makeSUT()
        sut.simulateAppearance()
        loader.completeFeedLoading()
        XCTAssertEqual(loader.loadMoreCallCount, 0)
        
        sut.simulateLoadMoreFeedAction()
        XCTAssertEqual(loader.loadMoreCallCount, 1)
        
        sut.simulateLoadMoreFeedAction()
        XCTAssertEqual(loader.loadMoreCallCount, 1, "Expected no request while loading more")
        
        loader.completeLoadMore(lastPage: false, at: .zero)
        sut.simulateLoadMoreFeedAction()
        XCTAssertEqual(loader.loadMoreCallCount, 2)
        
        loader.completeLoadMoreWithError(at: 1)
        sut.simulateLoadMoreFeedAction()
        XCTAssertEqual(loader.loadMoreCallCount, 3)
        
        loader.completeLoadMore(lastPage: true, at: 2)
        sut.simulateLoadMoreFeedAction()
        XCTAssertEqual(loader.loadMoreCallCount, 3)
    }
    
    func test_loadingMoreIndicator_isVisibleWhileLoadingMore() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        XCTAssertFalse(sut.isShowingLoadingMoreIndicator())
        
        loader.completeFeedLoading(at: 0)
        XCTAssertFalse(sut.isShowingLoadingMoreIndicator())
        
        sut.simulateLoadMoreFeedAction()
        XCTAssertTrue(sut.isShowingLoadingMoreIndicator())
        
        loader.completeLoadMore(at: .zero)
        XCTAssertFalse(sut.isShowingLoadingMoreIndicator())
        
        sut.simulateLoadMoreFeedAction()
        XCTAssertTrue(sut.isShowingLoadingMoreIndicator())
        
        loader.completeLoadMoreWithError(at: 1)
        XCTAssertFalse(sut.isShowingLoadingMoreIndicator())
    }
    
    func test_loadMoreCompletion_dispatchesFromBackgroundToMainThread() {
        let (sut, loader) = makeSUT()
        sut.simulateAppearance()
        loader.completeFeedLoading()
        sut.simulateLoadMoreFeedAction()
        
        let exp = expectation(description: "Wait for the more loading completion")
        DispatchQueue.global().async { [weak loader] in
            loader?.completeLoadMore()
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
    }
    
    // MARK: Helpers
    
    private func makeSUT(
        onSelectFeedImage: @escaping (FeedImage) -> Void = { _ in },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: ListViewController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedUIComposer.feedComposedWith(
            feedLoader: loader.loadPublisher,
            imageLoader: loader.loadImageDataPublisher,
            onSelectFeedImage: onSelectFeedImage
        )
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
    
    private func anyImageData() -> Data {
        return UIImage.make(withColor: .green).pngData()!
    }
}

// swiftlint:enable force_unwrapping
// swiftlint:enable type_body_length
// swiftlint:enable file_length
