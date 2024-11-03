import EssentialFeed
import EssentialFeediOS
import XCTest

// swiftlint:disable force_unwrapping

final class ImageCommentsSnapshotTests: XCTestCase {
    func test_listWithComments() {
        let sut = makeSUT()
        
        sut.display(comments())
        
        assert(snapshot: sut.snapshot(for: .iPhone16Pro(style: .light)), named: "IMAGE_COMMENTS_LIGHT")
        assert(snapshot: sut.snapshot(for: .iPhone16Pro(style: .dark)), named: "IMAGE_COMMENTS_DARK")
        assert(
            snapshot: sut.snapshot(for: .iPhone16Pro(style: .light, contentSize: .extraExtraExtraLarge)),
            named: "IMAGE_COMMENTS_LIGHT_EXTRA_EXTRA_EXTRA_LARGE"
        )
    }
    
    // MARK: Helpers
    
    private func makeSUT() -> ListViewController {
        let bundle = Bundle(for: ListViewController.self)
        let storyboard = UIStoryboard(name: "ImageComments", bundle: bundle)
        let controller = storyboard.instantiateInitialViewController { coder in
            return ListViewController(coder: coder)
        }!
        controller.loadViewIfNeeded()
        controller.tableView.showsVerticalScrollIndicator = false
        controller.tableView.showsHorizontalScrollIndicator = false
        return controller
    }
    
    private func comments() -> [CellController] {
        return commentControllers().map { CellController(id: UUID(), dataSource: $0) }
    }
    
    private func commentControllers() -> [ImageCommentCellController] {
        return [
            ImageCommentCellController(
                viewModel: ImageCommentViewModel(
                    // swiftlint:disable:next line_length
                    message: "The East Side Gallery is an open-air gallery in Berlin. It consists of a series of murals painted directly on a 1,316 m long remnant of the Berlin Wall, located near the centre of Berlin, on Mühlenstraße in Friedrichshain-Kreuzberg. The gallery has official status as a Denkmal, or heritage-protected landmark.",
                    date: "1000 years ago",
                    username: "a super-super long long long username"
                )
            ),
            ImageCommentCellController(
                viewModel: ImageCommentViewModel(
                    message: "Garth Pier is a Grade II listed structure in Bangor, Gwynedd, North Wales.",
                    date: "4 min ago",
                    username: "a username"
                )
            ),
            ImageCommentCellController(
                viewModel: ImageCommentViewModel(
                    message: "A short message",
                    date: "Yesterday",
                    username: "un"
                )
            )
        ]
    }
}

// swiftlint:enable force_unwrapping
