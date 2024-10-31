import Foundation

private struct InvalidImageDataError: Error {}

public final class FeedImagePresenter<View: FeedImageLoadingView, Image> where View.Image == Image {
    private let view: View
    private let imageTransformer: (Data) -> Image?
    
    public init(view: View, imageTransformer: @escaping (Data) -> Image?) {
        self.view = view
        self.imageTransformer = imageTransformer
    }
    
    public static func map(_ image: FeedImage) -> FeedImageLoadingViewModel<Image> {
        return FeedImageLoadingViewModel(
            description: image.description,
            location: image.location,
            image: nil,
            isLoading: false,
            shouldRetry: false
        )
    }
    
    public func didStartLoadingImage(for model: FeedImage) {
        let viewModel = FeedImageLoadingViewModel<Image>(
            description: model.description,
            location: model.location,
            image: nil,
            isLoading: true,
            shouldRetry: false
        )
        view.display(viewModel)
    }
    
    public func didFinishLoadingImage(with data: Data, for model: FeedImage) {
        guard let image = imageTransformer(data) else {
            return didFinishLoadingImage(with: InvalidImageDataError(), for: model)
        }
        
        let viewModel = FeedImageLoadingViewModel(
            description: model.description,
            location: model.location,
            image: image,
            isLoading: false,
            shouldRetry: false
        )
        view.display(viewModel)
    }
    
    public func didFinishLoadingImage(with error: Error, for model: FeedImage) {
        let viewModel = FeedImageLoadingViewModel<Image>(
            description: model.description,
            location: model.location,
            image: nil,
            isLoading: false,
            shouldRetry: true
        )
        view.display(viewModel)
    }
}
