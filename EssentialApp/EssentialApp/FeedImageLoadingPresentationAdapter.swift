import Combine
import EssentialFeed
import EssentialFeediOS
import Foundation

final class FeedImageLoadingPresentationAdapter
<View: FeedImageLoadingView, Image>: FeedImageCellControllerDelegate
where View.Image == Image {
    private let feedImage: FeedImage
    private let imageLoader: (URL) -> FeedImageDataLoader.Publisher
    var imagePresenter: FeedImagePresenter<View, Image>?
    
    private var cancellable: Cancellable?
    
    init(feedImage: FeedImage, imageLoader: @escaping (URL) -> FeedImageDataLoader.Publisher) {
        self.feedImage = feedImage
        self.imageLoader = imageLoader
    }
    
    func didRequestImage() {
        imagePresenter?.didStartLoadingImage(for: feedImage)
        
        cancellable = imageLoader(feedImage.url).sink(
            receiveCompletion: { [weak imagePresenter, feedImage] completion in
                switch completion {
                case .finished:
                    break
                    
                case .failure(let error):
                    imagePresenter?.didFinishLoadingImage(with: error, for: feedImage)
                }
            },
            receiveValue: { [weak imagePresenter, feedImage] data in
                imagePresenter?.didFinishLoadingImage(with: data, for: feedImage)
            }
        )
    }
    
    func didCancelImageRequest() {
        cancellable?.cancel()
        cancellable = nil
    }
}
