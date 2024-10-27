import EssentialFeed
import Foundation

final class MainQueueDispatchDecorator<T> {
    private let decoratee: T
    
    init(decoratee: T) {
        self.decoratee = decoratee
    }
    
    func executeOnMainThread(_ completion: @escaping () -> Void) {
        // swiftlint:disable:next void_function_in_ternary
        Thread.isMainThread ? completion() : DispatchQueue.main.async(execute: completion)
    }
}

extension MainQueueDispatchDecorator: FeedImageDataLoader where T == FeedImageDataLoader {
    func loadImageData(
        from url: URL,
        completion: @escaping LoadImageResultCompletion
    ) -> any FeedImageDataLoaderTask {
        decoratee.loadImageData(from: url) { [weak self] result in
            self?.executeOnMainThread { completion(result) }
        }
    }
}
