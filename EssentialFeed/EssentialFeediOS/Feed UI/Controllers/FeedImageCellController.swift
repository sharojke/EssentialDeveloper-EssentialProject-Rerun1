import EssentialFeed
import UIKit

public protocol FeedImageCellControllerDelegate {
    func didRequestImage()
    func didCancelImageRequest()
}

public final class FeedImageCellController: NSObject {
    private let viewModel: FeedImageViewModel
    private let delegate: FeedImageCellControllerDelegate
    private let onSelect: () -> Void
    private var cell: FeedImageCell?
    
    public init(
        viewModel: FeedImageViewModel,
        delegate: FeedImageCellControllerDelegate,
        onSelect: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.delegate = delegate
        self.onSelect = onSelect
    }
    
    private func preload() {
        delegate.didRequestImage()
    }
    
    private func cancelLoad() {
        releaseCellForReuse()
        delegate.didCancelImageRequest()
    }
    
    private func releaseCellForReuse() {
        cell?.onReuse = nil
        cell = nil
    }
}

extension FeedImageCellController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: FeedImageCell = tableView.dequeueReusableCell()
        self.cell = cell
        
        cell.locationContainer.isHidden = !viewModel.hasLocation
        cell.locationLabel.text = viewModel.location
        cell.descriptionLabel.text = viewModel.description
        cell.onRetry = { [weak self] in
            self?.delegate.didRequestImage()
        }
        cell.onReuse = { [weak self] in
            self?.releaseCellForReuse()
        }
        delegate.didRequestImage()
        return cell
    }
}

extension FeedImageCellController: UITableViewDelegate {
    public func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        self.cell = cell as? FeedImageCell
        delegate.didRequestImage()
    }
    
    public func tableView(
        _ tableView: UITableView,
        didEndDisplaying cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        cancelLoad()
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        onSelect()
    }
}

extension FeedImageCellController: UITableViewDataSourcePrefetching {
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        preload()
    }
    
    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        cancelLoad()
    }
}

extension FeedImageCellController: ResourceView {
    public typealias ResourceViewModel = UIImage
    
    public func display(_ viewModel: UIImage) {
        cell?.feedImageView.setImageAnimated(viewModel)
    }
}

extension FeedImageCellController: ResourceLoadingView {
    public func display(_ viewModel: ResourceLoadingViewModel) {
        cell?.feedImageContainer.isShimmering = viewModel.isLoading
    }
}

extension FeedImageCellController: ResourceErrorView {
    public func display(_ viewModel: ResourceErrorViewModel) {
        cell?.feedImageRetryButton.isHidden = viewModel.message == nil
    }
}
