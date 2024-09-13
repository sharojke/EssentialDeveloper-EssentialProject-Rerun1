import Foundation

public protocol FeedLoader {
    typealias LoadResult = Result<[FeedImage], Error>
    
    func load(completion: @escaping (LoadResult) -> Void)
}
