import EssentialFeed

public enum FeedUIComposer {
    public static func feedComposedWith(
        feedLoader: FeedLoader,
        feedImageDataLoader: FeedImageDataLoader
    ) -> FeedViewController {
        let refreshController = FeedRefreshViewController(feedLoader: feedLoader)
        let feedController = FeedViewController(refreshController: refreshController)
        refreshController.onRefresh = adaptFeedToCellControllers(
            forwardingTo: feedController,
            loader: feedImageDataLoader
        )
        return feedController
    }
    
    private static func adaptFeedToCellControllers(
        forwardingTo controller: FeedViewController,
        loader: FeedImageDataLoader
    ) -> ([FeedImage]) -> Void {
        return { [weak controller] feed in
            controller?.tableModel = feed.map { feedImage in
                return FeedImageCellController(model: feedImage, imageLoader: loader)
            }
        }
    }
}
