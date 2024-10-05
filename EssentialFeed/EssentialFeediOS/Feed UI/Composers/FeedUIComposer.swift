import EssentialFeed
import UIKit

// swiftlint:disable force_unwrapping

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

private final class FeedLoadingPresentationAdapter: FeedViewControllerDelegate {
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

final class MainQueueDispatchDecorator<T> {
    private let decoratee: T
    
    init(decoratee: T) {
        self.decoratee = decoratee
    }
    
    func executeOnMainThread(_ completion: @escaping () -> Void) {
        // swiftlint:disable:next void_function_in_ternary
        Thread.isMainThread ? completion() : DispatchQueue.main.async(execute: completion)
    }
}

public enum FeedUIComposer {
    public static func feedComposedWith(
        feedLoader: FeedLoader,
        imageLoader: FeedImageDataLoader
    ) -> FeedViewController {
        let presentationAdapter = FeedLoadingPresentationAdapter(
            feedLoader: MainQueueDispatchDecorator(decoratee: feedLoader)
        )
        let feedController = FeedViewController.makeWith(
            delegate: presentationAdapter,
            title: FeedPresenter.title
        )
        let feedViewAdapter = FeedViewAdapter(
            controller: feedController,
            loader: MainQueueDispatchDecorator(decoratee: imageLoader)
        )
        let feedPresenter = FeedPresenter(
            feedView: feedViewAdapter,
            loadingView: WeakRefVirtualProxy(feedController)
        )
        presentationAdapter.feedPresenter = feedPresenter
        return feedController
    }
}

private extension FeedViewController {
    static func makeWith(delegate: FeedViewControllerDelegate, title: String) -> FeedViewController {
        let bundle = Bundle(for: FeedViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let controller = storyboard.instantiateInitialViewController { coder in
            return FeedViewController(coder: coder, delegate: delegate)
        }!
        controller.title = title
        return controller
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

extension MainQueueDispatchDecorator: FeedLoader where T == FeedLoader {
    func load(completion: @escaping (LoadResult) -> Void) {
        decoratee.load { [weak self] result in
            self?.executeOnMainThread { completion(result) }
        }
    }
}

extension MainQueueDispatchDecorator: FeedImageDataLoader where T == FeedImageDataLoader {
    func loadImageData(
        from url: URL,
        completion: @escaping LoadImageResultCompletion
    ) -> any FeedImageDataLoaderTask {
        decoratee.loadImageData(from: url) { [weak self] result in
            self?.executeOnMainThread { completion(result) }
        }
    }
}

// swiftlint:enable force_unwrapping
