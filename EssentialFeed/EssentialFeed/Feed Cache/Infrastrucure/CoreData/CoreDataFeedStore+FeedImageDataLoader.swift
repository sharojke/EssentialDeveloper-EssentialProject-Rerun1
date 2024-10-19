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
            defer { completion(.success(Void())) }
            guard let image = try? ManagedFeedImage.first(with: url, in: context) else { return }
            
            image.data = data
//            try? context.save()
        }
    }
}
