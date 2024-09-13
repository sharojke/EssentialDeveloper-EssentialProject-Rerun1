import Foundation

private struct Root: Decodable {
    let items: [RemoteFeedItem]
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
