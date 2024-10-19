import Foundation

extension CoreDataFeedStore: FeedImageDataStore {
    public func retrieveData(for url: URL, completion: @escaping FeedImageDataStore.RetrieveCompletion) {
        perform { context in
            completion(Result { try ManagedFeedImage.first(with: url, in: context)?.data })
        }
    }
    
    public func insert(
        _ data: Data,
        for url: URL,
        completion: @escaping FeedImageDataStore.InsertCompletion
    ) {
        perform { context in
            completion(
                Result {
                    try ManagedFeedImage.first(with: url, in: context)
                        .map { $0.data = data }
//                        .map(context.save)
                }
            )
        }
    }
}
