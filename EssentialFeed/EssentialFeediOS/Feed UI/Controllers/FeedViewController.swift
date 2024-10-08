import UIKit

protocol FeedViewControllerDelegate {
    func didRequestFeedRefresh()
}

public final class FeedViewController: UITableViewController {
    private let delegate: FeedViewControllerDelegate
    private var onViewIsAppearing: ((FeedViewController) -> Void)?
    public let errorView = ErrorView()
    
    private lazy var _refreshControl: UIRefreshControl = {
        let view = UIRefreshControl()
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }()
    
    var tableModel = [FeedImageCellController]() {
        didSet { tableView.reloadData() }
    }
    
    override public var refreshControl: UIRefreshControl? {
        get {
            return _refreshControl
        }
        set {
            guard let newValue else { return }
            
            _refreshControl = newValue
        }
    }
    
    init?(coder: NSCoder, delegate: FeedViewControllerDelegate) {
        self.delegate = delegate
        super.init(coder: coder)
        
        onViewIsAppearing = { viewController in
            viewController.refresh()
            viewController.onViewIsAppearing = nil
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.prefetchDataSource = self
        refreshControl = _refreshControl
    }
    
    @IBAction private func refresh() {
        delegate.didRequestFeedRefresh()
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
        return controller.view(in: tableView)
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

// MARK: - FeedLoadingView

extension FeedViewController: FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel) {
        if viewModel.isLoading {
            refreshControl?.beginRefreshing()
        } else {
            refreshControl?.endRefreshing()
        }
    }
}
