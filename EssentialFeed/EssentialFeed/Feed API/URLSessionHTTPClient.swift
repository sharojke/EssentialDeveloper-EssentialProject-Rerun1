import Foundation

private struct UnexpectedValuesRepresentation: Error {}

public final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func get(from url: URL, completion: @escaping (HTTPClient.GetResult) -> Void) {
        session.dataTask(with: url) { data, response, error in
            completion(
                Result {
                    if let error {
                        throw error
                    } else if let data, let response = response as? HTTPURLResponse {
                        return (data, response)
                    } else {
                        throw UnexpectedValuesRepresentation()
                    }
                }
            )
        }
        .resume()
    }
}
