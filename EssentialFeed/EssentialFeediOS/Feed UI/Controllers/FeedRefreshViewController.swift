import UIKit

final class FeedRefreshViewController: NSObject {
    private let presenter: FeedPresenter
    private lazy var refreshControl: UIRefreshControl = {
        let view = UIRefreshControl()
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }()
    
    var view: UIRefreshControl {
        get { refreshControl }
        set { refreshControl = newValue }
    }
    
    init(presenter: FeedPresenter) {
        self.presenter = presenter
    }
    
    @objc
    func refresh() {
        presenter.loadFeed()
    }
}

extension FeedRefreshViewController: FeedLoadingView {
    func display(isLoading: Bool) {
        if isLoading {
            view.beginRefreshing()
        } else {
            view.endRefreshing()
        }
    }
}
