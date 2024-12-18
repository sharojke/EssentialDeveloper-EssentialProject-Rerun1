@testable import EssentialFeed
@testable import EssentialFeediOS
import XCTest

// swiftlint:disable force_unwrapping

private final class ImageStub: FeedImageCellControllerDelegate {
    let viewModel: FeedImageViewModel
    private let image: UIImage?
    weak var controller: FeedImageCellController?
    
    init(description: String?, location: String?, image: UIImage?) {
        viewModel = FeedImageViewModel(description: description, location: location)
        self.image = image
    }
    
    func didRequestImage() {
        controller?.display(ResourceLoadingViewModel(isLoading: false))
        
        if let image {
            controller?.display(image)
            controller?.display(ResourceErrorViewModel(message: nil))
        } else {
            controller?.display(ResourceErrorViewModel(message: "any"))
        }
    }
    
    func didCancelImageRequest() {}
}

final class FeedSnapshotTests: XCTestCase {
    func test_feedWithContent() {
        let sut = makeSUT()
        
        sut.display(feedWithContent())
        
        assert(
            snapshot: sut.snapshot(for: .iPhone16Pro(style: .light)),
            named: "FEED_WITH_CONTENT_LIGHT"
        )
        assert(
            snapshot: sut.snapshot(for: .iPhone16Pro(style: .dark)),
            named: "FEED_WITH_CONTENT_DARK"
        )
        assert(
            snapshot: sut.snapshot(for: .iPhone16Pro(style: .light, contentSize: .extraExtraExtraLarge)),
            named: "FEED_WITH_CONTENT_LIGHT_EXTRA_EXTRA_EXTRA_LARGE"
        )
    }
    
    func test_feedWithFailedImageLoading() {
        let sut = makeSUT()
        
        sut.display(feedWithFailedImageLoading())
        
        assert(
            snapshot: sut.snapshot(for: .iPhone16Pro(style: .light)),
            named: "FEED_WITH_FAILED_IMAGE_LOADING_LIGHT"
        )
        assert(
            snapshot: sut.snapshot(for: .iPhone16Pro(style: .dark)),
            named: "FEED_WITH_FAILED_IMAGE_LOADING_DARK"
        )
        assert(
            snapshot: sut.snapshot(for: .iPhone16Pro(style: .light, contentSize: .extraExtraExtraLarge)),
            named: "FEED_WITH_FAILED_IMAGE_LOADING_LIGHT_EXTRA_EXTRA_EXTRA_LARGE"
        )
    }
    
    func test_feedWithLoadMoreIndicator() {
        let sut = makeSUT()

        sut.display(feedWithLoadMoreIndicator())

        assert(
            snapshot: sut.snapshot(for: .iPhone16Pro(style: .light)),
            named: "FEED_WITH_LOAD_MORE_INDICATOR_LIGHT"
        )
        assert(
            snapshot: sut.snapshot(for: .iPhone16Pro(style: .dark)),
            named: "FEED_WITH_LOAD_MORE_INDICATOR_DARK"
        )
    }
    
    func test_feedWithLoadMoreError() {
        let sut = makeSUT()
        
        sut.display(feedWithLoadMoreError())
        
        assert(
            snapshot: sut.snapshot(for: .iPhone16Pro(style: .light)),
            named: "FEED_WITH_LOAD_MORE_ERROR_LIGHT"
        )
        assert(
            snapshot: sut.snapshot(for: .iPhone16Pro(style: .dark)),
            named: "FEED_WITH_LOAD_MORE_ERROR_DARK"
        )
        assert(
            snapshot: sut.snapshot(for: .iPhone16Pro(style: .light, contentSize: .extraExtraExtraLarge)),
            named: "FEED_WITH_LOAD_MORE_ERROR_LIGHT_EXTRA_EXTRA_EXTRA_LARGE"
        )
    }
}

private extension FeedSnapshotTests {
    func makeSUT() -> ListViewController {
        let bundle = Bundle(for: ListViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let controller = storyboard.instantiateInitialViewController { coder in
            return ListViewController(coder: coder)
        }!
        controller.loadViewIfNeeded()
        controller.tableView.showsVerticalScrollIndicator = false
        controller.tableView.showsHorizontalScrollIndicator = false
        return controller
    }
    
    func feedWithContent() -> [ImageStub] {
        return [
            ImageStub(
                // swiftlint:disable:next line_length
                description: "The East Side Gallery is an open-air gallery in Berlin. It consists of a series of murals painted directly on a 1,316 m long remnant of the Berlin Wall, located near the centre of Berlin, on Mühlenstraße in Friedrichshain-Kreuzberg. The gallery has official status as a Denkmal, or heritage-protected landmark.",
                location: "East Side Gallery\nMemorial in Berlin, Germany",
                image: UIImage.make(withColor: .red)
            ),
            ImageStub(
                description: "Garth Pier is a Grade II listed structure in Bangor, Gwynedd, North Wales.",
                location: "Garth Pier",
                image: UIImage.make(withColor: .green)
            )
        ]
    }
    
    func feedWithFailedImageLoading() -> [ImageStub] {
        return [
            ImageStub(
                description: "Garth Pier is a Grade II listed structure in Bangor, Gwynedd, North Wales.",
                location: "Garth Pier",
                image: nil
            ),
            ImageStub(
                description: nil,
                location: "At home",
                image: nil
            )
        ]
    }
    
    private func feedWithLoadMoreIndicator() -> [CellController] {
        let loadMoreCellController = LoadMoreCellController {}
        loadMoreCellController.display(ResourceLoadingViewModel(isLoading: true))
        return feedWith(loadMore: loadMoreCellController)
    }
    
    private func feedWithLoadMoreError() -> [CellController] {
        let loadMoreCellController = LoadMoreCellController {}
        loadMoreCellController.display(ResourceErrorViewModel(message: "This is a multiline\nerror message"))
        return feedWith(loadMore: loadMoreCellController)
    }
    
    private func feedWith(loadMore: LoadMoreCellController) -> [CellController] {
        let stub = feedWithContent().last!
        let cellController = FeedImageCellController(viewModel: stub.viewModel, delegate: stub, onSelect: {})
        stub.controller = cellController
        
        return [
            CellController(id: UUID(), dataSource: cellController),
            CellController(id: UUID(), dataSource: loadMore)
        ]
    }
}

private extension ListViewController {
    func display(_ stubs: [ImageStub]) {
        let cells = stubs
            .map { stub in
                let cellController = FeedImageCellController(
                    viewModel: stub.viewModel,
                    delegate: stub,
                    onSelect: {}
                )
                stub.controller = cellController
                return CellController(id: UUID(), dataSource: cellController)
            }
        display(cells)
    }
}

// swiftlint:enable force_unwrapping
