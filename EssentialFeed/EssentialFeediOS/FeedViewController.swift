import EssentialFeed
import UIKit

public final class FeedViewController: UITableViewController {
    private let loader: FeedLoader
    private var onViewIsAppearing: ((FeedViewController) -> Void)?
    private var feed = [FeedImage]()
    
    public init(loader: FeedLoader) {
        self.loader = loader
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
        loader.load { [weak self] result in
            self?.stopRefreshing()
            
            switch result {
            case .success(let feed):
                self?.feed = feed
                self?.tableView.reloadData()
                
            case .failure:
                break
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
        return cell
    }
}
