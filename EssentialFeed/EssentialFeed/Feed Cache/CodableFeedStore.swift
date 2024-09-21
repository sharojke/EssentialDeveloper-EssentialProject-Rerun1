import Foundation

public final class CodableFeedStore: FeedStore {
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date
        
        var localFeed: LocalFeed {
            return LocalFeed(feed: feed.map(\.local), timestamp: timestamp)
        }
    }
    
    private struct CodableFeedImage: Equatable, Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL
        
        init(_ image: LocalFeedImage) {
            id = image.id
            description = image.description
            location = image.location
            url = image.url
        }
        
        var local: LocalFeedImage {
            return LocalFeedImage(id: id, description: description, location: location, url: url)
        }
    }
    
    private let storeURL: URL
    private let queue = DispatchQueue(label: "\(CodableFeedStore.self)Queue", qos: .userInitiated)
    
    public init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    public func deleteCachedFeed(completion: @escaping (DeleteResult) -> Void) {
        let storeURL = storeURL
        
        queue.async {
            guard FileManager.default.fileExists(atPath: storeURL.path()) else {
                return completion(.success(Void()))
            }
            
            do {
                try FileManager.default.removeItem(at: storeURL)
                completion(.success(Void()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping (InsertResult) -> Void) {
        let storeURL = storeURL
        
        queue.async {
            do {
                let encoder = JSONEncoder()
                let localFeed = Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp)
                let encoded = try encoder.encode(localFeed)
                try encoded.write(to: storeURL)
                completion(.success(Void()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func retrieve(completion: @escaping (RetrieveResult) -> Void) {
        let storeURL = storeURL
        
        queue.async {
            guard let data = try? Data(contentsOf: storeURL) else {
                return completion(.success(LocalFeed(feed: [], timestamp: Date())))
            }
            
            do {
                let decoder = JSONDecoder()
                let decoded = try decoder.decode(Cache.self, from: data)
                completion(.success(decoded.localFeed))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
