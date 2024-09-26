import EssentialFeed
import UIKit

public final class FeedViewController: UITableViewController {
    private let loader: FeedLoader
    private var onViewIsAppearing: ((FeedViewController) -> Void)?
    
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
        loader.load { [weak self] _ in
            self?.stopRefreshing()
        }
    }
    
    private func stopRefreshing() {
        refreshControl?.endRefreshing()
    }
}
