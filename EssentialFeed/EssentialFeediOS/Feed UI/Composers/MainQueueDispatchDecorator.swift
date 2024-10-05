import Foundation
import EssentialFeed

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

extension MainQueueDispatchDecorator: FeedLoader where T == FeedLoader {
    func load(completion: @escaping (LoadResult) -> Void) {
        decoratee.load { [weak self] result in
            self?.executeOnMainThread { completion(result) }
        }
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
