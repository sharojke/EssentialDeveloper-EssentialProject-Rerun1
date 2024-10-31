import Combine
import EssentialFeed
import EssentialFeediOS
import Foundation

public final class LoadResourcePresentationAdapter<Resource, View: ResourceView> {
    private let loader: () -> AnyPublisher<Resource, Error>
    private var cancellable: Cancellable?
    var resourcePresenter: LoadResourcePresenter<Resource, View>?
    
    init(loader: @escaping () -> AnyPublisher<Resource, Error>) {
        self.loader = loader
    }
    
    private func loadResource() {
        resourcePresenter?.didStartLoading()
        
        cancellable = loader().sink(
            receiveCompletion: { [weak resourcePresenter] completion in
                switch completion {
                case .finished:
                    break
                    
                case .failure(let error):
                    resourcePresenter?.didFinishLoading(with: error)
                }
            },
            receiveValue: { [weak resourcePresenter] resource in
                resourcePresenter?.didFinishLoading(with: resource)
            }
        )
    }
}

extension LoadResourcePresentationAdapter: FeedViewControllerDelegate {
    public func didRequestFeedRefresh() {
        loadResource()
    }
}
