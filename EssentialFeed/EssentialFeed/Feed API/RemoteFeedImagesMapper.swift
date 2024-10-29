import Foundation

private struct Root: Decodable {
    private struct RemoteFeedImage: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let image: URL
    }

    private let items: [RemoteFeedImage]
    
    var images: [FeedImage] {
        return items.map { item in
            return FeedImage(
                id: item.id,
                description: item.description,
                location: item.location,
                url: item.image
            )
        }
    }
}

enum RemoteFeedImagesMapper {
    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [FeedImage] {
        guard response.isOK,
              let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw RemoteFeedLoader.LoadError.invalidData
        }
        
        return root.images
    }
}
