import EssentialFeed
import Foundation

final class FeedImageDataLoaderSpy: FeedImageDataLoader {
    private(set) var loadedURLs = [URL]()
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var loadResult: Result<Data, Error>!
    
    func loadImageData(from url: URL) throws -> Data {
        loadedURLs.append(url)
        return try loadResult.get()
    }
    
    func completeLoading(with error: Error, at index: Int = .zero) {
        loadResult = .failure(error)
    }
    
    func completeLoading(with data: Data, at index: Int = .zero) {
        loadResult = .success(data)
    }
}
