import EssentialFeed
import Foundation

final class FeedLoaderStub: FeedLoader {
    private let result: LoadResult
    
    init(result: LoadResult) {
        self.result = result
    }
    
    func load(completion: @escaping (LoadResult) -> Void) {
        completion(result)
    }
}
