import Foundation

public final class RemoteLoader<Resource> {
    public typealias LoadResult = Result<Resource, Error>
    public typealias Mapper = (Data, HTTPURLResponse) throws -> Resource
    
    private let url: URL
    private let client: HTTPClient
    private let mapper: Mapper
    
    public init(url: URL, client: HTTPClient, mapper: @escaping Mapper) {
        self.url = url
        self.client = client
        self.mapper = mapper
    }
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        client.get(from: url) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case let .success((data, response)):
                completion(map(data, from: response))
                
            case .failure:
                completion(.failure(LoadError.connectivity))
            }
        }
    }
    
    private func map(_ data: Data, from response: HTTPURLResponse) -> LoadResult {
        do {
            let mapped = try mapper(data, response)
            return .success(mapped)
        } catch {
            return .failure(LoadError.invalidData)
        }
    }
}

public extension RemoteLoader {
    enum LoadError: Error {
        case connectivity
        case invalidData
    }
}
