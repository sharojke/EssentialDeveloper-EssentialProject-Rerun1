import EssentialFeed
import UIKit

public enum FeedUIComposer {
    public static func feedComposedWith(
        feedLoader: FeedLoader,
        feedImageDataLoader: FeedImageDataLoader
    ) -> FeedViewController {
        let feedViewModel = FeedViewModel(feedLoader: feedLoader)
        let refreshController = FeedRefreshViewController(viewModel: feedViewModel)
        let feedController = FeedViewController(refreshController: refreshController)
        feedViewModel.onFeedLoad = adaptFeedToCellControllers(
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
                return FeedImageCellController(
                    viewModel: FeedImageViewModel(
                        model: feedImage,
                        imageLoader: loader, 
                        imageTransformer: UIImage.init
                    )
                )
            }
        }
    }
}
