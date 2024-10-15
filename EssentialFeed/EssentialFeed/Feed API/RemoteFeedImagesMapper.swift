import Foundation

private struct Root: Decodable {
    let items: [RemoteFeedImage]
}

enum RemoteFeedImagesMapper {
    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [RemoteFeedImage] {
        guard response.isOK,
              let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw RemoteFeedLoader.LoadError.invalidData
        }
        
        return root.items
    }
}
