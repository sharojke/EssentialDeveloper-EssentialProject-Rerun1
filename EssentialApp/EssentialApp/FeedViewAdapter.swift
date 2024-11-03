import EssentialFeed
import EssentialFeediOS
import UIKit

final class FeedViewAdapter: ResourceView {
    private typealias WeakFeedImageCellController = WeakRefVirtualProxy<FeedImageCellController>
    private typealias ImageDataPresentationAdapter = LoadResourcePresentationAdapter<Data, WeakFeedImageCellController>
    
    private weak var controller: ListViewController?
    private let loader: (URL) -> FeedImageDataLoader.Publisher
    
    init(controller: ListViewController, loader: @escaping (URL) -> FeedImageDataLoader.Publisher) {
        self.controller = controller
        self.loader = loader
    }
    
    func display(_ viewModel: FeedViewModel) {
        let cellControllers = viewModel.feed.map { feedImage in
            let adapter = ImageDataPresentationAdapter { [loader] in
                loader(feedImage.url)
            }
            let view = FeedImageCellController(
                viewModel: FeedImagePresenter.map(feedImage),
                delegate: adapter
            )
            adapter.resourcePresenter = LoadResourcePresenter(
                resourceView: WeakRefVirtualProxy(view),
                loadingView: WeakRefVirtualProxy(view),
                errorView: WeakRefVirtualProxy(view),
                mapper: UIImage.tryToMakeFromData
            )
            return view
        }
        controller?.display(cellControllers)
    }
}

extension UIImage {
    private struct InvalidImageData: Error {}

    static func tryToMakeFromData(_ data: Data) throws -> UIImage {
        guard let image = UIImage(data: data) else {
            throw InvalidImageData()
        }
        
        return image
    }
}
