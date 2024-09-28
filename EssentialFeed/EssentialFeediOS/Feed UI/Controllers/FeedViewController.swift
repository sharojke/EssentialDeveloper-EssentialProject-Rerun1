import EssentialFeed
import UIKit

public final class FeedViewController: UITableViewController {
    private let refreshController: FeedRefreshViewController
    private let imageLoader: FeedImageDataLoader
    private var onViewIsAppearing: ((FeedViewController) -> Void)?
    private var imageLoaderTasks = [IndexPath: FeedImageDataLoaderTask]()
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
        let cellModel = feed[indexPath.row]
        let cell = FeedImageCell()
        cell.locationContainer.isHidden = cellModel.location == nil
        cell.locationLabel.text = cellModel.location
        cell.descriptionLabel.text = cellModel.description
        cell.feedImageView.image = nil
        cell.feedImageRetryButton.isHidden = true
        cell.feedImageContainer.startShimmering()
        
        let loadImage = { [weak self, weak cell] in
            guard let self else { return }
            
            imageLoaderTasks[indexPath] = imageLoader.loadImageData(from: cellModel.url) { [weak cell] result in
                let data = try? result.get()
                let image = data.flatMap(UIImage.init)
                cell?.feedImageView.image = image
                cell?.feedImageRetryButton.isHidden = image != nil
                cell?.feedImageContainer.stopShimmering()
            }
        }
        
        cell.onRetry = loadImage
        loadImage()
        
        return cell
    }
    
    override func tableView(
        _ tableView: UITableView,
        didEndDisplaying cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        cancelImageLoaderTask(at: indexPath)
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
            let cellModel = feed[indexPath.row]
            imageLoaderTasks[indexPath] = imageLoader.loadImageData(from: cellModel.url) { _ in }
        }
    }
    
    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach(cancelImageLoaderTask)
    }
}

// MARK: - Helpers

private extension FeedViewController {
//    func startImageLoaderTask(at indexPath: IndexPath) {}
    
    func cancelImageLoaderTask(at indexPath: IndexPath) {
        imageLoaderTasks[indexPath]?.cancel()
        imageLoaderTasks[indexPath] = nil
    }
}
