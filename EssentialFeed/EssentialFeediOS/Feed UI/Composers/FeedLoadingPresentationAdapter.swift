import EssentialFeed
import Foundation

final class FeedLoadingPresentationAdapter: FeedViewControllerDelegate {
    private let feedLoader: FeedLoader
    var feedPresenter: FeedPresenter?
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    func didRequestFeedRefresh() {
        feedPresenter?.didStartLoadingFeed()
        
        feedLoader.load { [weak feedPresenter] result in
            switch result {
            case .success(let feed):
                feedPresenter?.didFinishLoadingFeed(with: feed)
                
            case .failure(let error):
                feedPresenter?.didFinishLoadingFeed(with: error)
            }
        }
    }
}
