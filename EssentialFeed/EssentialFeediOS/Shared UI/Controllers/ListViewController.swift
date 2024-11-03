import EssentialFeed
import UIKit

public final class ListViewController: UITableViewController {
    public var onRefresh: () -> Void = {}
    private var onViewIsAppearing: ((ListViewController) -> Void)?
    
    private lazy var _refreshControl: UIRefreshControl = {
        let view = UIRefreshControl()
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }()
    
    private lazy var dataSource: UITableViewDiffableDataSource<Int, CellController> = {
        return UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, controller in
            return controller.dataSource.tableView(tableView, cellForRowAt: indexPath)
        }
    }()
    
    override public var refreshControl: UIRefreshControl? {
        get {
            return _refreshControl
        }
        set {
            guard let newValue else { return }
            
            _refreshControl = newValue
        }
    }
    
    public let errorView = ErrorView()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        onViewIsAppearing = { viewController in
            viewController.refresh()
            viewController.onViewIsAppearing = nil
        }
        
        configureErrorView()
        dataSource.defaultRowAnimation = .fade
        tableView.dataSource = dataSource
        tableView.prefetchDataSource = self
        refreshControl = _refreshControl
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.sizeHeaderToFit()
    }
    
    @IBAction private func refresh() {
        onRefresh()
    }
    
    override public func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        
        onViewIsAppearing?(self)
    }
    
    // This method is needed for the DiffableDataSource on iOS less than 15.0.
    // It helps to prevent UI collisions which happen due to the tableView is not reloading automatically on lower OS versions
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        guard #unavailable(iOS 15.0) else { return }
        
        let previous = previousTraitCollection?.preferredContentSizeCategory
        let current = traitCollection.preferredContentSizeCategory
        guard previous != current else { return }
        
        tableView.reloadData()
    }
    
    public func display(_ cellControllers: [CellController]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, CellController>()
        snapshot.appendSections([.zero])
        snapshot.appendItems(cellControllers, toSection: .zero)
        
        if #available(iOS 15.0, *) {
            dataSource.applySnapshotUsingReloadData(snapshot)
        } else {
            dataSource.apply(snapshot)
        }
    }
    
    private func configureErrorView() {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        containerView.addSubview(errorView)
        
        errorView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            errorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            errorView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            errorView.topAnchor.constraint(equalTo: containerView.topAnchor),
            errorView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        tableView.tableHeaderView = containerView
        errorView.onHide = { [weak self] in
            self?.tableView.beginUpdates()
            self?.tableView.sizeHeaderToFit()
            self?.tableView.endUpdates()
        }
    }
}

public extension ListViewController {
    override func tableView(
        _ tableView: UITableView,
        didEndDisplaying cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        let delegate = cellControllerForRow(at: indexPath)?.delegate
        delegate?.tableView?(tableView, didEndDisplaying: cell, forRowAt: indexPath)
    }
    
//    override func tableView(
//        _ tableView: UITableView,
//        willDisplay cell: UITableViewCell,
//        forRowAt indexPath: IndexPath
//    ) {
//        startImageLoaderTask(at: indexPath)
//    }
}

extension ListViewController: UITableViewDataSourcePrefetching {
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            let dataSourcePrefetching = cellControllerForRow(at: indexPath)?.dataSourcePrefetching
            dataSourcePrefetching?.tableView(tableView, prefetchRowsAt: [indexPath])
        }
    }
    
    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            let dataSourcePrefetching = cellControllerForRow(at: indexPath)?.dataSourcePrefetching
            dataSourcePrefetching?.tableView?(tableView, cancelPrefetchingForRowsAt: [indexPath])
        }
    }
}

// MARK: - Helpers

private extension ListViewController {
    func cellControllerForRow(at indexPath: IndexPath) -> CellController? {
        return dataSource.itemIdentifier(for: indexPath)
    }
}

// MARK: - FeedLoadingView

extension ListViewController: ResourceLoadingView {
    public func display(_ viewModel: ResourceLoadingViewModel) {
        if viewModel.isLoading {
            refreshControl?.beginRefreshing()
        } else {
            refreshControl?.endRefreshing()
        }
    }
}

// MARK: - FeedErrorView

extension ListViewController: ResourceErrorView {
    public func display(_ viewModel: ResourceErrorViewModel) {
        errorView.message = viewModel.message
    }
}
