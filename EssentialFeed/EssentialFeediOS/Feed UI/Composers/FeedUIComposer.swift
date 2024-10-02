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

private final class FeedLoadingPresentationAdapter: FeedRefreshViewControllerDelegate {
    private let feedLoader: FeedLoader
    var feedPresenter: FeedPresenter?
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    func didRequestFeedRefresh() {
        feedPresenter?.didStartLoadingFeed()
        
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

private final class FeedImageLoadingPresentationAdapter
<View: FeedImageLoadingView, Image>: FeedImageCellControllerDelegate
where View.Image == Image {
    private let feedImage: FeedImage
    private let imageLoader: FeedImageDataLoader
    var imagePresenter: FeedImagePresenter<View, Image>?
    
    private var task: FeedImageDataLoaderTask?
    
    init(feedImage: FeedImage, imageLoader: FeedImageDataLoader) {
        self.feedImage = feedImage
        self.imageLoader = imageLoader
    }
    
    func didRequestImage() {
        imagePresenter?.didStartLoadingImage(for: feedImage)
        
        task = imageLoader.loadImageData(from: feedImage.url) { [weak imagePresenter, feedImage] result in
            switch result {
            case .success(let data):
                imagePresenter?.didFinishLoadingImage(with: data, for: feedImage)
                
            case .failure(let error):
                imagePresenter?.didFinishLoadingImage(with: error, for: feedImage)
            }
        }
    }
    
    func didCancelImageRequest() {
        task?.cancel()
        task = nil
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
        let presentationAdapter = FeedLoadingPresentationAdapter(feedLoader: feedLoader)
        let refreshController = FeedRefreshViewController(delegate: presentationAdapter)
        let feedController = FeedViewController(refreshController: refreshController)
        
        let feedViewAdapter = FeedViewAdapter(controller: feedController, loader: imageLoader)
        let feedPresenter = FeedPresenter(
            feedView: feedViewAdapter,
            loadingView: WeakRefVirtualProxy(refreshController)
        )
        presentationAdapter.feedPresenter = feedPresenter
        return feedController
    }
}

extension WeakRefVirtualProxy: FeedLoadingView where T: FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel) {
        object?.display(viewModel)
    }
}

extension WeakRefVirtualProxy: FeedImageLoadingView where T: FeedImageLoadingView, T.Image == UIImage {
    func display(_ viewModel: FeedImageLoadingViewModel<UIImage>) {
        object?.display(viewModel)
    }
}
