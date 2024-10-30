import Foundation

private enum MapError: Error {
    case invalidData
}

public enum FeedImageDataMapper {
    public static func map(data: Data, from response: HTTPURLResponse) throws -> Data {
        guard response.isOK, !data.isEmpty else {
            throw MapError.invalidData
        }
        
        return data
    }
}
