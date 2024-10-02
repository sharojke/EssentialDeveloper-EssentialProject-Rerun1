import EssentialFeed
import UIKit

private final class FeedViewAdapter: FeedView {
    private weak var controller: FeedViewController?
    private let loader: FeedImageDataLoader
    
    init(controller: FeedViewController, loader: FeedImageDataLoader) {
        self.controller = controller
        self.loader = loader
    }
    
    func display(_ viewModel: FeedViewModel) {
        controller?.tableModel = viewModel.feed.map { feedImage in
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

private final class FeedLoadingPresentationAdapter {
    private let feedPresenter: FeedPresenter
    private let feedLoader: FeedLoader
    
    init(feedPresenter: FeedPresenter, feedLoader: FeedLoader) {
        self.feedPresenter = feedPresenter
        self.feedLoader = feedLoader
    }
    
    func loadFeed() {
        feedPresenter.didStartLoadingFeed()
        
        feedLoader.load { [weak feedPresenter] result in
            switch result {
            case .success(let feed):
                feedPresenter?.didFinishLoadingFeed(with: feed)
                
            case .failure(let error):
                feedPresenter?.didFinishLoadingWithError(with: error)
            }
        }
    }
}

private final class WeakRefVirtualProxy<T: AnyObject> {
    private weak var object: T?
    
    init(_ object: T) {
        self.object = object
    }
}

public enum FeedUIComposer {
    public static func feedComposedWith(
        feedLoader: FeedLoader,
        imageLoader: FeedImageDataLoader
    ) -> FeedViewController {
        let feedPresenter = FeedPresenter()
        let presentationAdapter = FeedLoadingPresentationAdapter(
            feedPresenter: feedPresenter,
            feedLoader: feedLoader
        )
        let refreshController = FeedRefreshViewController(loadFeed: presentationAdapter.loadFeed)
        let feedController = FeedViewController(refreshController: refreshController)
        
        feedPresenter.loadingView = WeakRefVirtualProxy(refreshController)
        feedPresenter.feedView = FeedViewAdapter(controller: feedController, loader: imageLoader)
        return feedController
    }
}

extension WeakRefVirtualProxy: FeedLoadingView where T: FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel) {
        object?.display(viewModel)
    }
}
