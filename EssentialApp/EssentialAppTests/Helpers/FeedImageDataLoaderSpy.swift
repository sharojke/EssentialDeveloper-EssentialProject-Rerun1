import EssentialFeed
import Foundation

final class FeedImageDataLoaderSpy: FeedImageDataLoader {
    private final class Task: FeedImageDataLoaderTask {
        private let onCancel: () -> Void
        
        init(onCancel: @escaping () -> Void) {
            self.onCancel = onCancel
        }
        
        func cancel() {
            onCancel()
        }
    }
    
    private(set) var loadedURLs = [URL]()
    private(set) var cancelledURLs = [URL]()
    private var loadCompletions = [LoadImageResultCompletion]()
    
    func loadImageData(
        from url: URL,
        completion: @escaping LoadImageResultCompletion
    ) -> FeedImageDataLoaderTask {
        loadedURLs.append(url)
        loadCompletions.append(completion)
        return Task { [weak self] in
            self?.cancelledURLs.append(url)
        }
    }
    
    func completeLoading(with error: Error, at index: Int = .zero) {
        loadCompletions[index](.failure(error))
    }
    
    func completeLoading(with data: Data, at index: Int = .zero) {
        loadCompletions[index](.success(data))
    }
}
