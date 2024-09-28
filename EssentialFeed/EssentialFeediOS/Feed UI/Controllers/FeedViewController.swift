import EssentialFeed
import UIKit

public final class FeedViewController: UITableViewController {
    private let refreshController: FeedRefreshViewController
    private let imageLoader: FeedImageDataLoader
    private var onViewIsAppearing: ((FeedViewController) -> Void)?
    private var cellControllers = [IndexPath: FeedImageCellController]()
    
    private var feed = [FeedImage]() {
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
    
    public init(feedLoader: FeedLoader, feedImageDataLoader: FeedImageDataLoader) {
        self.refreshController = FeedRefreshViewController(feedLoader: feedLoader)
        self.imageLoader = feedImageDataLoader
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.prefetchDataSource = self
        refreshControl = refreshController.view
        refreshController.onRefresh = { [weak self] feed in
            self?.feed = feed
        }
        
        onViewIsAppearing = { viewController in
            viewController.refreshController.refresh()
            viewController.onViewIsAppearing = nil
        }
    }
    
    override public func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        
        onViewIsAppearing?(self)
    }
}

public extension FeedViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feed.count
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
        removeCellController(at: indexPath)
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
        indexPaths.forEach(removeCellController)
    }
}

// MARK: - Helpers

private extension FeedViewController {
//    func startImageLoaderTask(at indexPath: IndexPath) {}
    
    func removeCellController(at indexPath: IndexPath) {
        cellControllers[indexPath] = nil
    }
    
    func cellControllerForRow(at indexPath: IndexPath) -> FeedImageCellController {
        let cellModel = feed[indexPath.row]
        let controller = FeedImageCellController(model: cellModel, imageLoader: imageLoader)
        cellControllers[indexPath] = controller
        return controller
    }
}
