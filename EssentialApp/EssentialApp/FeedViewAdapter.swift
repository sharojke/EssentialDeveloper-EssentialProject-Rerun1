import EssentialFeed
import EssentialFeediOS
import UIKit

final class FeedViewAdapter: ResourceView {
    private typealias WeakFeedImageCellController = WeakRefVirtualProxy<FeedImageCellController>
    private typealias ImageDataPresentationAdapter = LoadResourcePresentationAdapter<Data, WeakFeedImageCellController>
    // swiftlint:disable:next line_length
    private typealias LoadMorePresentationAdapter = LoadResourcePresentationAdapter<Paginated<FeedImage>, FeedViewAdapter>
    
    private weak var controller: ListViewController?
    private let loader: (URL) -> FeedImageDataLoader.Publisher
    private let onSelectFeedImage: (FeedImage) -> Void
    private let currentFeed: [FeedImage: CellController]
    
    init(
        controller: ListViewController,
        loader: @escaping (URL) -> FeedImageDataLoader.Publisher,
        onSelectFeedImage: @escaping (FeedImage) -> Void,
        currentFeed: [FeedImage: CellController] = [:]
    ) {
        self.controller = controller
        self.loader = loader
        self.onSelectFeedImage = onSelectFeedImage
        self.currentFeed = currentFeed
    }
    
    func display(_ viewModel: Paginated<FeedImage>) {
        guard let controller else { return }
        
        var currentFeed = currentFeed
        let feedSection = viewModel.items
            .map { feedImage in
                if let controller = currentFeed[feedImage] {
                    return controller
                }
                
                let adapter = ImageDataPresentationAdapter { [loader] in
                    loader(feedImage.url)
                }
                let view = FeedImageCellController(
                    viewModel: FeedImagePresenter.map(feedImage),
                    delegate: adapter,
                    onSelect: { [onSelectFeedImage] in
                        onSelectFeedImage(feedImage)
                    }
                )
                adapter.resourcePresenter = LoadResourcePresenter(
                    resourceView: WeakRefVirtualProxy(view),
                    loadingView: WeakRefVirtualProxy(view),
                    errorView: WeakRefVirtualProxy(view),
                    mapper: UIImage.tryToMakeFromData
                )
                let controller = CellController(id: feedImage, dataSource: view)
                currentFeed[feedImage] = controller
                return controller
            }
        
        guard let loadMorePublisher = viewModel.loadMorePublisher else {
            return controller.display(feedSection)
        }
        
        let loadMoreAdapter = LoadMorePresentationAdapter(loader: loadMorePublisher)
        let loadMore = LoadMoreCellController(callback: loadMoreAdapter.loadResource)
        loadMoreAdapter.resourcePresenter = LoadResourcePresenter(
            resourceView: FeedViewAdapter(
                controller: controller,
                loader: loader,
                onSelectFeedImage: onSelectFeedImage,
                currentFeed: currentFeed
            ),
            loadingView: WeakRefVirtualProxy(loadMore),
            errorView: WeakRefVirtualProxy(loadMore)
        )
        let loadMoreSection = [CellController(id: UUID(), dataSource: loadMore)]
        controller.display(feedSection, loadMoreSection)
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
