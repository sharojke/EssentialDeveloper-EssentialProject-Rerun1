import Foundation

public protocol FeedImageDataLoaderTask {
    func cancel()
}

public protocol FeedImageDataLoader {
    typealias LoadImageResult = Result<Data, Error>
    typealias LoadImageResultCompletion = (LoadImageResult) -> Void
    
    typealias SaveImageResult = Result<Void, Error>
    typealias SaveImageResultCompletion = (SaveImageResult) -> Void
    
    func loadImageData(
        from url: URL,
        completion: @escaping LoadImageResultCompletion
    ) -> FeedImageDataLoaderTask
}
