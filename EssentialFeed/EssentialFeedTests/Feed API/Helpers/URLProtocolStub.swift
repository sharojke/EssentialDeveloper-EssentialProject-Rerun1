import Foundation

final class URLProtocolStub: URLProtocol {
    private struct Stub {
        let onStartLoading: (URLProtocolStub) -> Void
    }
    
    private static let queue = DispatchQueue(label: "URLProtocolStub.queue")
    private static var _stub: Stub?
    private static var stub: Stub? {
        get { return queue.sync { _stub } }
        set { queue.sync { _stub = newValue } }
    }
    
    static func stub(data: Data?, response: URLResponse?, error: Error?) {
        stub = Stub { urlProtocol in
            guard let client = urlProtocol.client else { return }
            
            if let data {
                client.urlProtocol(urlProtocol, didLoad: data)
            }
            
            if let response {
                client.urlProtocol(urlProtocol, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error {
                client.urlProtocol(urlProtocol, didFailWithError: error)
            } else {
                client.urlProtocolDidFinishLoading(urlProtocol)
            }
        }
    }
    
    static func observeRequests(observer: @escaping (URLRequest) -> Void) {
        stub = Stub { urlProtocol in
            urlProtocol.client?.urlProtocolDidFinishLoading(urlProtocol)
            
            observer(urlProtocol.request)
        }
    }
    
    static func onStartLoading(observer: @escaping () -> Void) {
        stub = Stub { _ in observer() }
    }
    
    static func removeStub() {
        stub = nil
    }
    
    // if `true` means we handle this request and it's our responsibility
    // to complete it either with success of failure
    override final class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override final class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        Self.stub?.onStartLoading(self)
    }
    
    override func stopLoading() {}
}
