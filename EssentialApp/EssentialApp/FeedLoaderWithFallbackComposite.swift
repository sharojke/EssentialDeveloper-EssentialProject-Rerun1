import EssentialFeed
import Foundation

public final class FeedLoaderWithFallbackComposite: FeedLoader {
    private let primary: FeedLoader
    private let fallback: FeedLoader
    
    public init(primary: FeedLoader, fallback: FeedLoader) {
        self.primary = primary
        self.fallback = fallback
    }
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        primary.load { [weak self] primaryResult in
            switch primaryResult {
            case .success(let feed):
                completion(.success(feed))
                
            case .failure:
                self?.fallback.load(completion: completion)
            }
        }
    }
}
