import Foundation

private struct Root: Decodable {
    let items: [RemoteFeedImage]
}

enum RemoteImageCommentsMapper {
    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [RemoteFeedImage] {
        guard response.isOK,
              let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw RemoteImageCommentsLoader.LoadError.invalidData
        }
        
        return root.items
    }
}
