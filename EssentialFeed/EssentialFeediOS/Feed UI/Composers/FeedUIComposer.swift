import EssentialFeed

public enum FeedUIComposer {
    public static func feedComposedWith(
        feedLoader: FeedLoader,
        feedImageDataLoader: FeedImageDataLoader
    ) -> FeedViewController {
        let refreshController = FeedRefreshViewController(feedLoader: feedLoader)
        let feedController = FeedViewController(refreshController: refreshController)
        
        refreshController.onRefresh = { [weak feedController] feed in
            feedController?.tableModel = feed.map { feedImage in
                return FeedImageCellController(model: feedImage, imageLoader: feedImageDataLoader)
            }
        }
        
        return feedController
    }
}
