import EssentialFeed
import EssentialFeediOS
import UIKit

final class FeedViewAdapter: ResourceView {
    private typealias WeakFeedImageCellController = WeakRefVirtualProxy<FeedImageCellController>
    private typealias ImageDataPresentationAdapter = LoadResourcePresentationAdapter<Data, WeakFeedImageCellController>
    
    private weak var controller: ListViewController?
    private let loader: (URL) -> FeedImageDataLoader.Publisher
    private let onSelectFeedImage: (FeedImage) -> Void
    
    init(
        controller: ListViewController,
        loader: @escaping (URL) -> FeedImageDataLoader.Publisher,
        onSelectFeedImage: @escaping (FeedImage) -> Void
    ) {
        self.controller = controller
        self.loader = loader
        self.onSelectFeedImage = onSelectFeedImage
    }
    
    func display(_ viewModel: Paginated<FeedImage>) {
        let feedSection = viewModel.items
            .map { feedImage in
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
                return CellController(id: feedImage, dataSource: view)
            }
        
        let loadMore = LoadMoreCellController {
            viewModel.loadMore? { _ in }
        }
        let loadMoreSection = [CellController(id: UUID(), dataSource: loadMore)]
        
        controller?.display(feedSection, loadMoreSection)
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
