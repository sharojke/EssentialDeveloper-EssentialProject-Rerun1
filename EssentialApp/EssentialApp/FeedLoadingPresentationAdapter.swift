import Combine
import EssentialFeed
import EssentialFeediOS
import Foundation

public final class FeedLoadingPresentationAdapter: FeedViewControllerDelegate {
    private let feedLoader: () -> AnyPublisher<[FeedImage], Error>
    private var cancellable: Cancellable?
    var resourcePresenter: LoadResourcePresenter<[FeedImage], FeedViewAdapter>?
    
    init(feedLoader: @escaping () -> AnyPublisher<[FeedImage], Error>) {
        self.feedLoader = feedLoader
    }
    
    public func didRequestFeedRefresh() {
        resourcePresenter?.didStartLoading()
        
        cancellable = feedLoader().sink(
            receiveCompletion: { [weak resourcePresenter] completion in
                switch completion {
                case .finished:
                    break
                    
                case .failure(let error):
                    resourcePresenter?.didFinishLoading(with: error)
                }
            },
            receiveValue: { [weak resourcePresenter] feed in
                resourcePresenter?.didFinishLoading(with: feed)
            }
        )
    }
}
