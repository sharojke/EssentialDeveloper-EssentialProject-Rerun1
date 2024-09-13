import Foundation

private struct Root: Decodable {
    let items: [RemoteFeedItem]
}

struct RemoteFeedItem: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
}

enum RemoteFeedItemsMapper {
    private static var okStatusCode: Int {
        return 200
    }
    
    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [RemoteFeedItem] {
        guard response.statusCode == okStatusCode,
              let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw RemoteFeedLoader.LoadError.invalidData
        }
        
        return root.items
    }
}
