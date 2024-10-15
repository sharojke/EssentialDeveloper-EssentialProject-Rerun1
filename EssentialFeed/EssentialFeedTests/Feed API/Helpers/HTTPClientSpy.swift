import EssentialFeed
import Foundation

// swiftlint:disable force_unwrapping

final class HTTPClientSpy: HTTPClient {
    private struct Task: HTTPClientTask {
        private let onCancel: () -> Void
        
        init(onCancel: @escaping () -> Void) {
            self.onCancel = onCancel
        }
        
        func cancel() {
            onCancel()
        }
    }
    
    private var messages = [(url: URL, completion: (GetResult) -> Void)]()
    private(set) var cancelledURLs = [URL]()
    
    var requestedURLs: [URL] {
        return messages.map { $0.url }
    }
    
    func get(from url: URL, completion: @escaping (GetResult) -> Void) -> HTTPClientTask {
        messages.append((url, completion))
        return Task { [weak self] in
            self?.cancelledURLs.append(url)
        }
    }
    
    func complete(with error: Error, at index: Int = 0) {
        messages[index].completion(.failure(error))
    }
    
    func complete(with statusCode: Int, data: Data, at index: Int = 0) {
        let message = messages[index]
        let response = HTTPURLResponse(
            url: message.url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        message.completion(.success((data, response)))
    }
}

// swiftlint:enable force_unwrapping
