import EssentialFeed
import UIKit

public protocol FeedImageDataLoaderTask {
    func cancel()
}

public protocol FeedImageDataLoader {
    typealias LoadImageResult = Result<Data, Error>
    typealias LoadImageResultCompletion = (LoadImageResult) -> Void
    
    func loadImageData(
        from url: URL,
        completion: @escaping LoadImageResultCompletion
    ) -> FeedImageDataLoaderTask
}

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
    
    @objc
    private func refresh() {
        refreshControl?.beginRefreshing()
        feedLoader.load { [weak self] result in
            self?.stopRefreshing()
            
            if let feed = try? result.get() {
                self?.feed = feed
                self?.tableView.reloadData()
            }
        }
    }
    
    private func stopRefreshing() {
        refreshControl?.endRefreshing()
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
        cell.feedImageContainer.startShimmering()
        
        imageLoaderTasks[indexPath] = imageLoader.loadImageData(from: cellModel.url) { [weak cell] result in
            cell?.feedImageContainer.stopShimmering()
            
            if let data = try? result.get() {
                cell?.feedImageView.image = UIImage(data: data)
            }
        }
        
        return cell
    }
    
    override func tableView(
        _ tableView: UITableView,
        didEndDisplaying cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        imageLoaderTasks[indexPath]?.cancel()
        imageLoaderTasks[indexPath] = nil
    }
}
