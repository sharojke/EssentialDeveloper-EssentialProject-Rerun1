import EssentialFeed
import UIKit

public final class ImageCommentCellController {
    private let viewModel: ImageCommentViewModel
    
    public init(viewModel: ImageCommentViewModel) {
        self.viewModel = viewModel
    }
}

extension ImageCommentCellController: CellController {
    public func view(in tableView: UITableView) -> UITableViewCell {
        let cell: ImageCommentCell = tableView.dequeueReusableCell()        
        cell.messageLabel.text = viewModel.message
        cell.usernameLabel.text = viewModel.username
        cell.dateLabel.text = viewModel.date
        return cell
    }
    
    public func preload() {}
    public func cancelLoad() {}
}
