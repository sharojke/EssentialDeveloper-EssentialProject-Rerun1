import Foundation

private struct Root: Decodable {
    let items: [Item]
    
    var comments: [ImageComment] {
        return items.map { item in
            return ImageComment(
                id: item.id,
                message: item.message,
                createdAt: item.created_at,
                username: item.author.username
            )
        }
    }
}

private struct Item: Decodable {
    struct Author: Decodable {
        let username: String
    }
    
    let id: UUID
    let message: String
    let created_at: Date
    let author: Author
}

public enum ImageCommentsMapper {
    public static func map(_ data: Data, from response: HTTPURLResponse) throws -> [ImageComment] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard isOK(response),
              let root = try? decoder.decode(Root.self, from: data) else {
            throw RemoteImageCommentsLoader.LoadError.invalidData
        }
        
        return root.comments
    }
    
    private static func isOK(_ response: HTTPURLResponse) -> Bool {
        return (200...299).contains(response.statusCode)
    }
}
