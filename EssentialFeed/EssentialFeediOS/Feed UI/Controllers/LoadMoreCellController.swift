import EssentialFeed
import UIKit

public class LoadMoreCellController: NSObject {
    private let callback: () -> Void
    private var offsetObserver: NSKeyValueObservation?
    
    private lazy var cell: LoadMoreCell = {
        let cell = LoadMoreCell()
        cell.selectionStyle = .none
        return cell
    }()
    
    public init(callback: @escaping () -> Void) {
        self.callback = callback
    }
}

extension LoadMoreCellController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cell
    }
}

extension LoadMoreCellController: UITableViewDelegate {
    public func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        reloadIfNeeded()
        
        offsetObserver = tableView.observe(\.contentOffset, options: .new) { [weak self] tableView, _ in
            guard tableView.isDragging else { return }

            self?.reloadIfNeeded()
        }
    }

    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        offsetObserver = nil
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        reloadIfNeeded()
    }
    
    func reloadIfNeeded() {
        guard !cell.isLoading else { return }
        
        callback()
    }
}

extension LoadMoreCellController: ResourceLoadingView {
    public func display(_ viewModel: ResourceLoadingViewModel) {
        cell.isLoading = viewModel.isLoading
    }
}

extension LoadMoreCellController: ResourceErrorView {
    public func display(_ viewModel: ResourceErrorViewModel) {
        cell.message = viewModel.message
    }
}
