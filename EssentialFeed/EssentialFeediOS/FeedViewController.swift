import EssentialFeed
import UIKit

public protocol FeedImageDataLoader {
    func loadImageData(from url: URL)
    func cancelImageDataLoad(from url: URL)
}

public final class FeedViewController: UITableViewController {
    private let feedLoader: FeedLoader
    private let imageLoader: FeedImageDataLoader
    private var onViewIsAppearing: ((FeedViewController) -> Void)?
    private var feed = [FeedImage]()
    
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
        imageLoader.loadImageData(from: cellModel.url)
        return cell
    }
    
    override func tableView(
        _ tableView: UITableView,
        didEndDisplaying cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        let cellModel = feed[indexPath.row]
        imageLoader.cancelImageDataLoad(from: cellModel.url)
    }
}
