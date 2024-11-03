import EssentialFeed
import EssentialFeediOS
import XCTest

// swiftlint:disable force_unwrapping

final class ListSnapshotTests: XCTestCase {
    func test_emptyList() {
        let sut = makeSUT()
        
        sut.display(emptyList())
        
        assert(
            snapshot: sut.snapshot(for: .iPhone16Pro(style: .light)),
            named: "LIST_EMPTY_LIGHT"
        )
        assert(
            snapshot: sut.snapshot(for: .iPhone16Pro(style: .dark)),
            named: "LIST_EMPTY_DARK"
        )
//        record(
//            snapshot: sut.snapshot(for: .iPhone16Pro(style: .light, contentSize: .extraExtraExtraLarge)),
//            named: "LIST_EMPTY_LIGHT_EXTRA_EXTRA_EXTRA_LARGE"
//        )
//        record(
//            snapshot: sut.snapshot(for: .iPhone16Pro(style: .dark, contentSize: .extraExtraExtraLarge)),
//            named: "LIST_EMPTY_DARK_EXTRA_EXTRA_EXTRA_LARGE"
//        )
    }
    
    func test_listWithErrorMessage() {
        let sut = makeSUT()
        
        sut.display(ResourceErrorViewModel(message: "This is a\nmulti-line\nerror message"))
        
        assert(
            snapshot: sut.snapshot(for: .iPhone16Pro(style: .light)),
            named: "LIST_WITH_ERROR_MESSAGE_LIGHT"
        )
        assert(
            snapshot: sut.snapshot(for: .iPhone16Pro(style: .dark)),
            named: "LIST_WITH_ERROR_MESSAGE_DARK"
        )
//        record(
//            snapshot: sut.snapshot(for: .iPhone16Pro(style: .light, contentSize: .extraExtraExtraLarge)),
//            named: "LIST_EMPTY_LIGHT_EXTRA_EXTRA_EXTRA_LARGE"
//        )
//        record(
//            snapshot: sut.snapshot(for: .iPhone16Pro(style: .dark, contentSize: .extraExtraExtraLarge)),
//            named: "LIST_EMPTY_DARK_EXTRA_EXTRA_EXTRA_LARGE"
//        )
    }
    
    // MARK: Helpers
    
    func makeSUT() -> ListViewController {
        let bundle = Bundle(for: ListViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let controller = storyboard.instantiateInitialViewController { coder in
            return ListViewController(coder: coder, onRefresh: {})
        }!
        controller.loadViewIfNeeded()
        controller.tableView.showsVerticalScrollIndicator = false
        controller.tableView.showsHorizontalScrollIndicator = false
        return controller
    }
    
    func emptyList() -> [CellController] {
        return []
    }
}

// swiftlint:enable force_unwrapping
