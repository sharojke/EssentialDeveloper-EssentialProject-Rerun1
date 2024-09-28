import EssentialFeed
import UIKit

public final class FeedViewController: UITableViewController {
    private let feedLoader: FeedLoader
    private let imageLoader: FeedImageDataLoader
    private var onViewIsAppearing: ((FeedViewController) -> Void)?
    private var feed = [FeedImage]()
    private var imageLoaderTasks = [IndexPath: FeedImageDataLoaderTask]()
    
    public init(feedLoader: FeedLoader, feedImageDataLoader: FeedImageDataLoader) {
        self.feedLoader = feedLoader
        self.imageLoader = feedImageDataLoader
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.prefetchDataSource = self
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        onViewIsAppearing = { viewController in
            viewController.refresh()
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
    @objc
    func refresh() {
        refreshControl?.beginRefreshing()
        feedLoader.load { [weak self] result in
            self?.stopRefreshing()
            
            if let feed = try? result.get() {
                self?.feed = feed
                self?.tableView.reloadData()
            }
        }
    }
    
    func stopRefreshing() {
        refreshControl?.endRefreshing()
    }
    
//    func startImageLoaderTask(at indexPath: IndexPath) {}
    
    func cancelImageLoaderTask(at indexPath: IndexPath) {
        imageLoaderTasks[indexPath]?.cancel()
        imageLoaderTasks[indexPath] = nil
    }
}
