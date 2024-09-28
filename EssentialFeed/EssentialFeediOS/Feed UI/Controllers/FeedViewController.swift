import EssentialFeed
import UIKit

public final class FeedViewController: UITableViewController {
    private let refreshController: FeedRefreshViewController
    private var onViewIsAppearing: ((FeedViewController) -> Void)?
    
    var tableModel = [FeedImageCellController]() {
        didSet { tableView.reloadData() }
    }
    
    override public var refreshControl: UIRefreshControl? {
        get {
            return refreshController.view
        }
        set {
            guard let newValue else { return }
            
            refreshController.view = newValue
        }
    }
    
    init(refreshController: FeedRefreshViewController) {
        self.refreshController = refreshController
        super.init(nibName: nil, bundle: nil)
        
        onViewIsAppearing = { viewController in
            viewController.refreshController.refresh()
            viewController.onViewIsAppearing = nil
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.prefetchDataSource = self
        refreshControl = refreshController.view
    }
    
    override public func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        
        onViewIsAppearing?(self)
    }
}

public extension FeedViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableModel.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let controller = cellControllerForRow(at: indexPath)
        return controller.view()
    }
    
    override func tableView(
        _ tableView: UITableView,
        didEndDisplaying cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        cancelCellControllerLoad(at: indexPath)
    }
    
//    override func tableView(
//        _ tableView: UITableView,
//        willDisplay cell: UITableViewCell,
//        forRowAt indexPath: IndexPath
//    ) {
//        startImageLoaderTask(at: indexPath)
//    }
}

extension FeedViewController: UITableViewDataSourcePrefetching {
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            cellControllerForRow(at: indexPath).preload()
        }
    }
    
    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach(cancelCellControllerLoad)
    }
}

// MARK: - Helpers

private extension FeedViewController {
    func cancelCellControllerLoad(at indexPath: IndexPath) {
        cellControllerForRow(at: indexPath).cancelLoad()
    }
    
    func cellControllerForRow(at indexPath: IndexPath) -> FeedImageCellController {
        return tableModel[indexPath.row]
    }
}
