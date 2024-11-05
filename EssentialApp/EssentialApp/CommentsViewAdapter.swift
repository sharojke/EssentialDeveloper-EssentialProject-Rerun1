import EssentialFeed
import EssentialFeediOS
import Foundation

final class CommentsViewAdapter: ResourceView {
    private weak var controller: ListViewController?
    
    init(controller: ListViewController) {
        self.controller = controller
    }
    
    func display(_ viewModel: ImageCommentsViewModel) {
        let cellControllers = viewModel.comments
            .map { comment in
                let view = ImageCommentCellController(viewModel: comment)
                return CellController(id: comment, dataSource: view)
            }
        controller?.display(cellControllers)
    }
}
