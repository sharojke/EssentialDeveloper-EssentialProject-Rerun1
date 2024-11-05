import EssentialFeediOS
import UIKit

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

// MARK: - ListViewController+Appearance

extension ListViewController {
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

// MARK: - ListViewController+RefreshUIAndLogic

extension ListViewController {
    func simulateUserInitiatedReload() {
        refreshControl?.simulatePullToRefresh()
    }
    
    func isShowingLoadingIndicator() -> Bool {
        return refreshControl?.isRefreshing == true
    }
}

// MARK: - ListViewController+Items

extension ListViewController {
    var feedImagesSection: Int { .zero }
    
    func renderedFeedImageData(at index: Int = .zero) -> Data? {
        return simulateFeedImageViewVisible(at: index)?.renderedImage
    }
    
    func numberOfRenderedFeedImageViews() -> Int {
        lazy var numberOfRows = tableView.numberOfRows(inSection: feedImagesSection)
        return tableView.numberOfSections == .zero ? .zero : numberOfRows
    }
    
    func feedImageView(at index: Int) -> FeedImageCell? {
        guard numberOfRenderedFeedImageViews() > index else { return nil }
        
        let ds = tableView.dataSource
        let indexPath = IndexPath(row: index, section: feedImagesSection)
        return ds?.tableView(tableView, cellForRowAt: indexPath) as? FeedImageCell
    }
    
    @discardableResult
    func simulateFeedImageViewVisible(at index: Int) -> FeedImageCell? {
        return feedImageView(at: index)
    }
    
    @discardableResult
    func simulateFeedImageViewNotVisible(at index: Int) -> FeedImageCell? {
        guard let view = simulateFeedImageViewVisible(at: index) else { return nil }
        
        let indexPath = IndexPath(row: index, section: feedImagesSection)
        let delegate = tableView.delegate
        delegate?.tableView?(tableView, didEndDisplaying: view, forRowAt: indexPath)
        return view
    }
    
    func simulateFeedImageViewNearVisible(at index: Int) {
        let ds = tableView.prefetchDataSource
        let indexPath = IndexPath(row: index, section: feedImagesSection)
        ds?.tableView(tableView, prefetchRowsAt: [indexPath])
    }
    
    func simulateFeedImageViewNotNearVisible(at index: Int) {
        simulateFeedImageViewNearVisible(at: index)
        let ds = tableView.prefetchDataSource
        let indexPath = IndexPath(row: index, section: feedImagesSection)
        ds?.tableView?(tableView, cancelPrefetchingForRowsAt: [indexPath])
    }
    
    @discardableResult
    func simulateFeedImageBecomingVisibleAgain(at row: Int) -> FeedImageCell? {
        guard let view = simulateFeedImageViewNotVisible(at: row) else { return nil }
        
        let delegate = tableView.delegate
        let index = IndexPath(row: row, section: feedImagesSection)
        delegate?.tableView?(tableView, willDisplay: view, forRowAt: index)
        return view
    }
}

// MARK: - ListViewController+Error

extension ListViewController {
    var errorMessage: String? {
        return errorView.message
    }
    
    func simulateTapOnErrorMessage() {
        errorView.simulateTap()
    }
}

// MARK: - ListViewController+Items
extension ListViewController {
    var commentsSection: Int { .zero }
    
    func numberOfRenderedCommentsViews() -> Int {
        lazy var numberOfRows = tableView.numberOfRows(inSection: commentsSection)
        return tableView.numberOfSections == .zero ? .zero : numberOfRows
    }
    
    func imageCommentView(at index: Int) -> ImageCommentCell? {
        guard numberOfRenderedCommentsViews() > index else { return nil }
        
        let ds = tableView.dataSource
        let indexPath = IndexPath(row: index, section: commentsSection)
        return ds?.tableView(tableView, cellForRowAt: indexPath) as? ImageCommentCell
    }
    
    func commentMessage(at index: Int) -> String? {
        return imageCommentView(at: index)?.messageLabel.text
    }
    
    func commentDate(at index: Int) -> String? {
        return imageCommentView(at: index)?.dateLabel.text
    }
    
    func commentUsername(at index: Int) -> String? {
        return imageCommentView(at: index)?.usernameLabel.text
    }
}
