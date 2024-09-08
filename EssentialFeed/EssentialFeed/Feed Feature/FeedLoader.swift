import Foundation

public protocol FeedLoader {
    typealias LoadResult = Result<[FeedItem], Error>
    
    func load(completion: @escaping (LoadResult) -> Void)
}
