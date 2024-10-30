@testable import EssentialFeed
@testable import EssentialFeediOS
import XCTest

// swiftlint:disable force_unwrapping

private final class ImageStub: FeedImageCellControllerDelegate {
    private let viewModel: FeedImageLoadingViewModel<UIImage>
    weak var controller: FeedImageCellController?
    
    init(description: String?, location: String?, image: UIImage?) {
        viewModel = FeedImageLoadingViewModel(
            description: description,
            location: location,
            image: image,
            isLoading: false,
            shouldRetry: image == nil
        )
    }
    
    func didRequestImage() {
        controller?.display(viewModel)
    }
    
    func didCancelImageRequest() {}
}

private final class DummyFeedViewControllerDelegate: FeedViewControllerDelegate {
    func didRequestFeedRefresh() {}
}

final class FeedSnapshotTests: XCTestCase {
    func test_feedWithContent() {
        let sut = makeSUT()
        
        sut.display(feedWithContent())
        
        assert(
            snapshot: sut.snapshot(for: .iPhone16Pro(style: .light)),
            named: "FEED_WITH_CONTENT_light"
        )
        assert(
            snapshot: sut.snapshot(for: .iPhone16Pro(style: .dark)),
            named: "FEED_WITH_CONTENT_dark"
        )
//        assert(
//            snapshot: sut.snapshot(for: .iPhone16Pro(style: .light, contentSize: .extraExtraExtraLarge)),
//            named: "FEED_WITH_CONTENT_light_extraExtraExtraLarge"
//        )
//        assert(
//            snapshot: sut.snapshot(for: .iPhone16Pro(style: .dark, contentSize: .extraExtraExtraLarge)),
//            named: "FEED_WITH_CONTENT_dark_extraExtraExtraLarge"
//        )
    }
    
    func test_feedWithFailedImageLoading() {
        let sut = makeSUT()
        
        sut.display(feedWithFailedImageLoading())
        
        assert(
            snapshot: sut.snapshot(for: .iPhone16Pro(style: .light)),
            named: "FEED_WITH_FAILED_IMAGE_LOADING_light"
        )
        assert(
            snapshot: sut.snapshot(for: .iPhone16Pro(style: .dark)),
            named: "FEED_WITH_FAILED_IMAGE_LOADING_dark"
        )
//        assert(
//            snapshot: sut.snapshot(for: .iPhone16Pro(style: .light, contentSize: .extraExtraExtraLarge)),
//            named: "FEED_WITH_FAILED_IMAGE_LOADING_light_extraExtraExtraLarge"
//        )
//        assert(
//            snapshot: sut.snapshot(for: .iPhone16Pro(style: .dark, contentSize: .extraExtraExtraLarge)),
//            named: "FEED_WITH_FAILED_IMAGE_LOADING_dark_extraExtraExtraLarge"
//        )
    }
}

private extension FeedSnapshotTests {
    func makeSUT() -> FeedViewController {
        let bundle = Bundle(for: FeedViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let delegate = DummyFeedViewControllerDelegate()
        let controller = storyboard.instantiateInitialViewController { coder in
            return FeedViewController(coder: coder, delegate: delegate)
        }!
        controller.loadViewIfNeeded()
        controller.tableView.showsVerticalScrollIndicator = false
        controller.tableView.showsHorizontalScrollIndicator = false
        return controller
    }
    
    func emptyFeed() -> [FeedImageCellController] {
        return []
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
}

private extension FeedViewController {
    func display(_ stubs: [ImageStub]) {
        let cells = stubs.map { stub in
            let cellController = FeedImageCellController(delegate: stub)
            stub.controller = cellController
            return cellController
        }
        display(cells)
    }
}

// swiftlint:enable force_unwrapping