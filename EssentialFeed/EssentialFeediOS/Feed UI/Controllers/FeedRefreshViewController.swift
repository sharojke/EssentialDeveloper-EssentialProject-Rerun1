import UIKit

final class FeedRefreshViewController: NSObject {
    private let viewModel: FeedViewModel
    private lazy var refreshControl = binded(UIRefreshControl())
    
    var view: UIRefreshControl {
        get { refreshControl }
        set { refreshControl = binded(newValue) }
    }
    
    init(viewModel: FeedViewModel) {
        self.viewModel = viewModel
    }
    
    @objc
    func refresh() {
        viewModel.loadFeed()
    }
    
    private func stopRefreshing() {
        view.endRefreshing()
    }
    
    private func binded(_ view: UIRefreshControl) -> UIRefreshControl {
        viewModel.onChange = { [weak self, weak view] viewModel in
            if viewModel.isLoading {
                view?.beginRefreshing()
            } else {
                self?.stopRefreshing()
            }
        }
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }
}
