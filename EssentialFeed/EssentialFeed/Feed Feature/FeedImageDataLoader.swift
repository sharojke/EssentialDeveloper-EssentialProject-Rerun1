import Foundation

public protocol FeedImageDataLoaderTask {
    func cancel()
}

public protocol FeedImageDataLoader {
    typealias LoadImageResult = Result<Data, Error>
    typealias LoadImageResultCompletion = (LoadImageResult) -> Void
    
    func loadImageData(
        from url: URL,
        completion: @escaping LoadImageResultCompletion
    ) -> FeedImageDataLoaderTask
}
