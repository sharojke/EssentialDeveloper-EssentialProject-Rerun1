import EssentialFeed
import EssentialFeediOS
import UIKit
import XCTest

// swiftlint:disable file_length
// swiftlint:disable force_unwrapping
// swiftlint:disable force_cast
// swiftlint:disable type_body_length

private final class LoaderSpy: FeedLoader, FeedImageDataLoader {
    private final class TaskSpy: FeedImageDataLoaderTask {
        private let onCancel: () -> Void
        
        init(onCancel: @escaping () -> Void) {
            self.onCancel = onCancel
        }
        
        func cancel() {
            onCancel()
        }
    }
    
    private var feedRequests = [(LoadResult) -> Void]()
    private var imageRequests = [(url: URL, completion: LoadImageResultCompletion)]()
    private(set) var cancelledImageURLs = [URL]()
    
    var loadedImageURLs: [URL] {
        return imageRequests.map(\.url)
    }
    
    var loadFeedCallCount: Int {
        return feedRequests.count
    }
    
    func load(completion: @escaping (LoadResult) -> Void) {
        feedRequests.append(completion)
    }
    
    func completeFeedLoading(with feed: [FeedImage] = [], at index: Int = .zero) {
        feedRequests[index](.success(feed))
    }
    
    func completeFeedLoadingWithError(at index: Int) {
        feedRequests[index](.failure(anyNSError()))
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

private final class FakeRefreshControl: UIRefreshControl {
    private var _isRefreshing = false
    
    override var isRefreshing: Bool { _isRefreshing }
    
    override func beginRefreshing() {
        _isRefreshing = true
    }
    
    override func endRefreshing() {
        _isRefreshing = false
    }
}

final class FeedViewControllerTests: XCTestCase {
    func test_loadFeedActions_requestFeedFromLoader() {
        let (sut, loader) = makeSUT()
        XCTAssertEqual(loader.loadFeedCallCount, .zero, "Expected no requests before view is appeared")
        
        sut.simulateAppearance()
        XCTAssertEqual(loader.loadFeedCallCount, 1, "Expected a request after view is appeared")
        
        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(loader.loadFeedCallCount, 2, "Expected another request after initiating a load")
        
        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(loader.loadFeedCallCount, 3, "Expected another request after initiating another load")
    }
    
    func test_loadingFeedIndicator_isVisibleWhileLoadingFeed() {
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
    
    func test_loadFeedCompletion_rendersSuccessfullyLoadedFeed() {
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
    
    func test_loadFeedCompletion_doesNotAlterCurrentRenderingStateOnError() {
        let image0 = makeImage()
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [image0], at: .zero)
        assertThat(sut, isRendering: [image0])
        
        sut.simulateUserInitiatedFeedReload()
        loader.completeFeedLoadingWithError(at: 1)
        assertThat(sut, isRendering: [image0])
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
            view0.isShowingImageLoadingIndicator,
            true,
            "Expected loading indicator for the first view while loading the first image"
        )
        XCTAssertEqual(
            view1.isShowingImageLoadingIndicator,
            true,
            "Expected loading indicator for the second view while loading the second image"
        )
        
        loader.completeImageLoading(at: .zero)
        XCTAssertEqual(
            view0.isShowingImageLoadingIndicator,
            false,
            "Expected no loading indicator for the first view after the first image is loaded"
        )
        XCTAssertEqual(
            view1.isShowingImageLoadingIndicator,
            true,
            "Expected loading indicator for the second view after the first image is loaded"
        )
        
        loader.completeImageLoading(at: 1)
        XCTAssertEqual(
            view0.isShowingImageLoadingIndicator,
            false,
            "Expected no loading indicator for the first view after the second image is loaded"
        )
        XCTAssertEqual(
            view1.isShowingImageLoadingIndicator,
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
            view0.renderedImage,
            nil,
            "Expected no image for the first view while loading the first image"
        )
        XCTAssertEqual(
            view1.renderedImage,
            nil,
            "Expected no image for the second view while loading the second image"
        )
        
        let imageData0 = UIImage.make(withColor: .green).pngData()!
        loader.completeImageLoading(with: imageData0, at: .zero)
        XCTAssertEqual(
            view0.renderedImage,
            imageData0,
            "Expected image for the first view after the first image is loaded"
        )
        XCTAssertEqual(
            view1.renderedImage,
            nil,
            "Expected no image for the second view after the first image is loaded"
        )
        
        let imageData1 = UIImage.make(withColor: .red).pngData()!
        loader.completeImageLoading(with: imageData1, at: 1)
        XCTAssertEqual(
            view0.renderedImage,
            imageData0,
            "Expected no image change for the first view after the second image is loaded"
        )
        XCTAssertEqual(
            view1.renderedImage,
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
            view0.isShowingRetryAction,
            false,
            "Expected no retry for the first view while loading the first image"
        )
        XCTAssertEqual(
            view1.isShowingRetryAction,
            false,
            "Expected no retry for the second view while loading the second image"
        )
        
        loader.completeImageLoadingWithError(at: .zero)
        XCTAssertEqual(
            view0.isShowingRetryAction,
            true,
            "Expected retry for the first view after loading the first image fails"
        )
        XCTAssertEqual(
            view1.isShowingRetryAction,
            false,
            "Expected no retry for the second view after loading the first image fails"
        )
        
        loader.completeImageLoadingWithError(at: 1)
        XCTAssertEqual(
            view0.isShowingRetryAction,
            true,
            "Expected no retry change for the first view after loading the second image fails"
        )
        XCTAssertEqual(
            view1.isShowingRetryAction,
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
            view.isShowingRetryAction,
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
        
        view0.simulateRetryAction()
        XCTAssertEqual(
            loader.loadedImageURLs,
            [image0.url, image1.url, image0.url],
            "Expected three image URLs after retry action for the first view"
        )
        
        view1.simulateRetryAction()
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
            "Expected two first image URLs after the second view is near visible"
        )
    }
    
    // MARK: Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: FeedViewController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedViewController(feedLoader: loader, feedImageDataLoader: loader)
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
        _ sut: FeedViewController,
        isRendering feed: [FeedImage],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
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
    }
    
    private func assertThat(
        _ sut: FeedViewController,
        hasConfiguredFor image: FeedImage,
        at index: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let shouldLocationBeVisible = image.location != nil
        let view = sut.feedImageView(at: index)
        XCTAssertEqual(
            view.isShowingLocation,
            shouldLocationBeVisible,
            "Expected `isShowingLocation` to be \(shouldLocationBeVisible) for index at \(index)",
            file: file,
            line: line
        )
        XCTAssertEqual(
            view.locationText,
            image.location,
            "Expected `locationText` to be \(image.location as Any) for index at \(index)",
            file: file,
            line: line
        )
        XCTAssertEqual(
            view.descriptionText,
            image.description,
            "Expected `descriptionText` to be \(image.description as Any) for index at \(index)",
            file: file,
            line: line
        )
    }
}

private extension UIRefreshControl {
    func simulatePullToRefresh() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .valueChanged)?.forEach { action in
                (target as NSObject).perform(Selector(action))
            }
        }
    }
}

private extension UIButton {
    func simulateTap() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .touchUpInside)?
                .forEach { (target as NSObject).perform(Selector($0)) }
        }
    }
}

// MARK: - FeedViewController+Appearance

private extension FeedViewController {
    func simulateAppearance() {
        if !isViewLoaded {
            loadViewIfNeeded()
            replaceRefreshControlWithFakeForiOS17Support()
        }
        
        beginAppearanceTransition(true, animated: false)
        endAppearanceTransition()
    }
    
    private func replaceRefreshControlWithFakeForiOS17Support() {
        let fake = FakeRefreshControl()
        
        refreshControl?.allTargets.forEach { target in
            refreshControl?.actions(forTarget: target, forControlEvent: .valueChanged)?.forEach { action in
                fake.addTarget(target, action: Selector(action), for: .valueChanged)
            }
        }
        
        refreshControl = fake
    }
}

// MARK: - FeedViewController+RefreshUIAndLogic

private extension FeedViewController {
    func simulateUserInitiatedFeedReload() {
        refreshControl?.simulatePullToRefresh()
    }
    
    func isShowingLoadingIndicator() -> Bool {
        return refreshControl?.isRefreshing == true
    }
}

// MARK: - FeedViewController+Items

private extension FeedViewController {
    var feedImagesSection: Int { .zero }
    
    func numberOfRenderedFeedImageViews() -> Int {
        return tableView.numberOfRows(inSection: feedImagesSection)
    }
    
    func feedImageView(at index: Int) -> FeedImageCell {
        let ds = tableView.dataSource
        let indexPath = IndexPath(row: index, section: feedImagesSection)
        return ds?.tableView(tableView, cellForRowAt: indexPath) as! FeedImageCell
    }
    
    @discardableResult
    func simulateFeedImageViewVisible(at index: Int) -> FeedImageCell {
        return feedImageView(at: index)
    }
    
    func simulateFeedImageViewNotVisible(at index: Int) {
        let view = simulateFeedImageViewVisible(at: index)
        let indexPath = IndexPath(row: index, section: feedImagesSection)
        let delegate = tableView.delegate
        delegate?.tableView?(tableView, didEndDisplaying: view, forRowAt: indexPath)
    }
    
    func simulateFeedImageViewNearVisible(at index: Int) {
        let ds = tableView.prefetchDataSource
        let indexPath = IndexPath(row: index, section: feedImagesSection)
        ds?.tableView(tableView, prefetchRowsAt: [indexPath])
    }
}

private extension FeedImageCell {
    var isShowingLocation: Bool {
        return !locationContainer.isHidden
    }
    
    var locationText: String? {
        return locationLabel.text
    }
    
    var descriptionText: String? {
        return descriptionLabel.text
    }
    
    var isShowingImageLoadingIndicator: Bool {
        return feedImageContainer.isShimmering
    }
    
    var renderedImage: Data? {
        return feedImageView.image?.pngData()
    }
    
    var isShowingRetryAction: Bool {
        return !feedImageRetryButton.isHidden
    }
    
    func simulateRetryAction() {
        feedImageRetryButton.simulateTap()
    }
}

private extension UIImage {
    static func make(withColor color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        
        return UIGraphicsImageRenderer(size: rect.size, format: format).image { rendererContext in
            color.setFill()
            rendererContext.fill(rect)
        }
    }
}

// swiftlint:enable force_unwrapping
// swiftlint:enable force_cast
// swiftlint:enable type_body_length
// swiftlint:enable file_length
