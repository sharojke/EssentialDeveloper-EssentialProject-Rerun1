import EssentialFeed
import UIKit

final class FeedViewAdapter: FeedView {
    private weak var controller: FeedViewController?
    private let loader: FeedImageDataLoader
    
    init(controller: FeedViewController, loader: FeedImageDataLoader) {
        self.controller = controller
        self.loader = loader
    }
    
    func display(_ viewModel: FeedViewModel) {
        controller?.tableModel = viewModel.feed.map { feedImage in
            let adapter = FeedImageLoadingPresentationAdapter<WeakRefVirtualProxy<FeedImageCellController>, UIImage>(
                feedImage: feedImage,
                imageLoader: loader
            )
            let view = FeedImageCellController(delegate: adapter)
            adapter.imagePresenter = FeedImagePresenter(
                view: WeakRefVirtualProxy(view),
                imageTransformer: UIImage.init
            )
            return view
        }
    }
}
