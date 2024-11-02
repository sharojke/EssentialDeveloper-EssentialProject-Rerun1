import EssentialFeed
import EssentialFeediOS
import UIKit

private struct InvalidImageData: Error {}

final class FeedViewAdapter: ResourceView {
    private typealias WeakFeedImageCellController = WeakRefVirtualProxy<FeedImageCellController>
    private typealias PresentationAdapter = LoadResourcePresentationAdapter<Data, WeakFeedImageCellController>
    
    private weak var controller: FeedViewController?
    private let loader: (URL) -> FeedImageDataLoader.Publisher
    
    init(controller: FeedViewController, loader: @escaping (URL) -> FeedImageDataLoader.Publisher) {
        self.controller = controller
        self.loader = loader
    }
    
    func display(_ viewModel: FeedViewModel) {
        let cellControllers = viewModel.feed.map { feedImage in
            let adapter = PresentationAdapter { [loader] in
                loader(feedImage.url)
            }
            let view = FeedImageCellController(
                viewModel: FeedImagePresenter<FeedImageCellController, UIImage>.map(feedImage),
                delegate: adapter
            )
            adapter.resourcePresenter = LoadResourcePresenter(
                resourceView: WeakRefVirtualProxy(view),
                loadingView: WeakRefVirtualProxy(view),
                errorView: WeakRefVirtualProxy(view),
                mapper: { data in
                    guard let image = UIImage(data: data) else { throw InvalidImageData() }
                    
                    return image
                }
            )
            return view
        }
        controller?.display(cellControllers)
    }
}
