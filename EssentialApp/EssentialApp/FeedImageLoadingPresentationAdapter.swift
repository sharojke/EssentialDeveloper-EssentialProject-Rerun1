import EssentialFeed
import EssentialFeediOS
import Foundation

final class FeedImageLoadingPresentationAdapter
<View: FeedImageLoadingView, Image>: FeedImageCellControllerDelegate
where View.Image == Image {
    private let feedImage: FeedImage
    private let imageLoader: FeedImageDataLoader
    var imagePresenter: FeedImagePresenter<View, Image>?
    
    private var task: FeedImageDataLoaderTask?
    
    init(feedImage: FeedImage, imageLoader: FeedImageDataLoader) {
        self.feedImage = feedImage
        self.imageLoader = imageLoader
    }
    
    func didRequestImage() {
        imagePresenter?.didStartLoadingImage(for: feedImage)
        
        task = imageLoader.loadImageData(from: feedImage.url) { [weak imagePresenter, feedImage] result in
            switch result {
            case .success(let data):
                imagePresenter?.didFinishLoadingImage(with: data, for: feedImage)
                
            case .failure(let error):
                imagePresenter?.didFinishLoadingImage(with: error, for: feedImage)
            }
        }
    }
    
    func didCancelImageRequest() {
        task?.cancel()
        task = nil
    }
}
