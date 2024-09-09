import Foundation

public protocol HTTPClient {
    typealias GetResult = Result<(Data, HTTPURLResponse), Error>
    
    func get(from url: URL, completion: @escaping (GetResult) -> Void)
}
