import Foundation

private struct Root: Decodable {
    let items: [RemoteFeedImage]
}

enum RemoteFeedImagesMapper {
    private static var okStatusCode: Int {
        return 200
    }
    
    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [RemoteFeedImage] {
        guard response.statusCode == okStatusCode,
              let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw RemoteFeedLoader.LoadError.invalidData
        }
        
        return root.items
    }
}
