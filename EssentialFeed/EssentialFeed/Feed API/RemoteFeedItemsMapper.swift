import Foundation

private struct Root: Decodable {
    let items: [Item]
    
    var feed: [FeedItem] {
        return items.map(\.item)
    }
}

private struct Item: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
    
    var item: FeedItem {
        return FeedItem(
            id: id,
            description: description,
            location: location,
            imageURL: image
        )
    }
}

enum RemoteFeedItemsMapper {
    private static var okStatusCode: Int {
        return 200
    }
    
    static func map(_ data: Data, from response: HTTPURLResponse) -> RemoteFeedLoader.LoadResult {
        guard response.statusCode == okStatusCode,
              let root = try? JSONDecoder().decode(Root.self, from: data) else {
            return .failure(RemoteFeedLoader.LoadError.invalidData)
        }
        
        return .success(root.feed)
    }
}
