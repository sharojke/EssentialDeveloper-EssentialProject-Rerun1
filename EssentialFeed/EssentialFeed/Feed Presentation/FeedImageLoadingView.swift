import Foundation

public protocol FeedImageLoadingView {
    associatedtype Image
    
    func display(_ viewModel: FeedImageLoadingViewModel<Image>)
}
