import EssentialFeed
import Foundation

final class FeedImageViewModel<Image> {
    typealias Observer<T> = (T) -> Void
    
    private let model: FeedImage
    private let imageLoader: FeedImageDataLoader
    private let imageTransformer: (Data) -> Image?
    private var task: FeedImageDataLoaderTask?
    
    var onImageLoad: Observer<Image?>?
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
    
    init(
        model: FeedImage,
        imageLoader: FeedImageDataLoader,
        imageTransformer: @escaping (Data) -> Image?
    ) {
        self.model = model
        self.imageLoader = imageLoader
        self.imageTransformer = imageTransformer
    }
    
    func loadImageData() {
        onImageLoad?(nil)
        onImageLoadingStateChange?(true)
        onShouldRetryImageLoadStateChange?(false)
        
        task = imageLoader.loadImageData(from: model.url) { [weak self] result in
            self?.handle(result)
        }
    }
    
    func cancelImageDataLoad() {
        task?.cancel()
    }
    
    private func handle(_ result: Result<Data, any Error>) {
        let data = try? result.get()
        let image = data.flatMap(imageTransformer)
        onImageLoad?(image)
        onImageLoadingStateChange?(false)
        onShouldRetryImageLoadStateChange?(image == nil)
    }
}
