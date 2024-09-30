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
    
    private func binded(_ view: UIRefreshControl) -> UIRefreshControl {
        viewModel.onLoadingStateChange = { [weak view] isLoading in
            if isLoading {
                view?.beginRefreshing()
            } else {
                view?.endRefreshing()
            }
        }
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }
}
