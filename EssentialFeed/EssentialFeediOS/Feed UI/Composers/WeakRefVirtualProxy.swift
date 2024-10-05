import EssentialFeed
import UIKit

final class WeakRefVirtualProxy<T: AnyObject> {
    private weak var object: T?
    
    init(_ object: T) {
        self.object = object
    }
}

extension WeakRefVirtualProxy: FeedLoadingView where T: FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel) {
        object?.display(viewModel)
    }
}

extension WeakRefVirtualProxy: FeedImageLoadingView where T: FeedImageLoadingView, T.Image == UIImage {
    func display(_ viewModel: FeedImageLoadingViewModel<UIImage>) {
        object?.display(viewModel)
    }
}
