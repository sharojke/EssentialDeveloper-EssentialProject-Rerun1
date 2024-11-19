import Combine
import EssentialFeed
import EssentialFeediOS
import Foundation

public final class LoadResourcePresentationAdapter<Resource, View: ResourceView> {
    private let loader: () -> AnyPublisher<Resource, Error>
    private var cancellable: Cancellable?
    private var isLoading = false
    var resourcePresenter: LoadResourcePresenter<Resource, View>?
    
    init(loader: @escaping () -> AnyPublisher<Resource, Error>) {
        self.loader = loader
    }
    
    func loadResource() {
        guard !isLoading else { return }
        
        resourcePresenter?.didStartLoading()
        isLoading = true
        
        cancellable = loader()
            .handleEvents(receiveCancel: { [weak self] in
                self?.isLoading = false
            })
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        break
                        
                    case .failure(let error):
                        self?.resourcePresenter?.didFinishLoading(with: error)
                    }
                    self?.isLoading = false
                },
                receiveValue: { [weak resourcePresenter] resource in
                    resourcePresenter?.didFinishLoading(with: resource)
                }
            )
    }
}

extension LoadResourcePresentationAdapter: FeedImageCellControllerDelegate {
    public func didRequestImage() {
        loadResource()
    }
    
    public func didCancelImageRequest() {
        cancellable?.cancel()
        cancellable = nil
    }
}
