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
    
    private func numberOfRows(in section: Int) -> Int {
        return tableView.numberOfSections > section ? tableView.numberOfRows(inSection: section) : .zero
    }
    
    private func cell(at indexPath: IndexPath) -> UITableViewCell? {
        guard numberOfRows(in: indexPath.section) > indexPath.row else { return nil }
        
        let dataSource = tableView.dataSource
        return dataSource?.tableView(tableView, cellForRowAt: indexPath)
    }
    
    private func cell(row: Int, section: Int) -> UITableViewCell? {
        return cell(at: IndexPath(row: row, section: section))
    }
    
    func renderedFeedImageData(at index: Int = .zero) -> Data? {
        return simulateFeedImageViewVisible(at: index)?.renderedImage
    }
    
    func numberOfRenderedFeedImageViews() -> Int {
        return numberOfRows(in: feedImagesSection)
    }
    
    func feedImageView(at index: Int) -> FeedImageCell? {
        return cell(row: index, section: feedImagesSection) as? FeedImageCell
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
    
    func simulateTapOnFeedImage(at row: Int) {
        let delegate = tableView.delegate
        let index = IndexPath(row: row, section: feedImagesSection)
        delegate?.tableView?(tableView, didSelectRowAt: index)
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
        return numberOfRows(in: commentsSection)
    }
    
    func imageCommentView(at index: Int) -> ImageCommentCell? {
        return cell(row: index, section: commentsSection) as? ImageCommentCell
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

extension ListViewController {
    private var feedLoadMoreSection: Int { 1 }
    
    func simulateLoadMoreFeedAction() {
        let (view, index) = loadMoreFeedCell()
        guard let view else { return }

        tableView.delegate?.tableView?(tableView, willDisplay: view, forRowAt: index)
    }
    
    func isShowingLoadingMoreIndicator() -> Bool {
        return loadMoreFeedCell().cell?.isLoading == true
    }
    
    private func loadMoreFeedCell() -> (cell: LoadMoreCell?, indexPath: IndexPath) {
        let indexPath = IndexPath(row: .zero, section: feedLoadMoreSection)
        return (cell(at: indexPath) as? LoadMoreCell, indexPath)
    }
}
