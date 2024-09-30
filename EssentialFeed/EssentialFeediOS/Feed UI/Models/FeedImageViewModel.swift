import EssentialFeed
import UIKit

final class FeedImageViewModel {
    typealias Observer<T> = (T) -> Void
    
    private let model: FeedImage
    private let imageLoader: FeedImageDataLoader
    private var task: FeedImageDataLoaderTask?
    
    var onImageLoad: Observer<UIImage?>?
    var onImageLoadingStateChange: Observer<Bool>?
    var onShouldRetryImageLoadStateChange: Observer<Bool>?
    
    var hasLocation: Bool {
        return location != nil
    }
    
    var location: String? {
        return model.location
    }
    
    var description: String? {
        return model.description
    }
    
    init(model: FeedImage, imageLoader: FeedImageDataLoader) {
        self.model = model
        self.imageLoader = imageLoader
    }
    
    func loadImageData() {
        onImageLoad?(nil)
        onImageLoadingStateChange?(true)
        onShouldRetryImageLoadStateChange?(false)
        
        task = imageLoader.loadImageData(from: model.url) { [weak self] result in
            let data = try? result.get()
            let image = data.flatMap(UIImage.init)
            self?.onImageLoad?(image)
            self?.onImageLoadingStateChange?(false)
            self?.onShouldRetryImageLoadStateChange?(image == nil)
        }
    }
    
    func cancelImageDataLoad() {
        task?.cancel()
    }
}
