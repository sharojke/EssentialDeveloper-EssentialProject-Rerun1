import Combine
import EssentialFeed
import EssentialFeediOS
import Foundation

public final class FeedLoadingPresentationAdapter: FeedViewControllerDelegate {
    private let feedLoader: () -> AnyPublisher<[FeedImage], Error>
    private var cancellable: Cancellable?
    var feedPresenter: FeedPresenter?
    
    init(feedLoader: @escaping () -> AnyPublisher<[FeedImage], Error>) {
        self.feedLoader = feedLoader
    }
    
    public func didRequestFeedRefresh() {
        feedPresenter?.didStartLoadingFeed()
        
        cancellable = feedLoader().sink(
            receiveCompletion: { [weak feedPresenter] completion in
                switch completion {
                case .finished:
                    break
                    
                case .failure(let error):
                    feedPresenter?.didFinishLoadingFeed(with: error)
                }
            },
            receiveValue: { [weak feedPresenter] feed in
                feedPresenter?.didFinishLoadingFeed(with: feed)
            }
        )
    }
}
