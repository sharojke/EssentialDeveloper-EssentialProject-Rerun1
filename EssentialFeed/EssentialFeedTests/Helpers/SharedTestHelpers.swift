import Foundation

// swiftlint:disable force_unwrapping
// swiftlint:disable force_try

func anyNSError() -> NSError {
    return NSError(domain: "", code: .zero)
}

func anyError() -> Error {
    return NSError(domain: "", code: .zero)
}

func anyURL() -> URL {
    return URL(string: "http://any-url.com")!
}

func anyData() -> Data {
    return Data("any data".utf8)
}

func makeItemsJSON(_ items: [[String: Any]]) -> Data {
    let json = ["items": items]
    return try! JSONSerialization.data(withJSONObject: json)
}

extension HTTPURLResponse {
    convenience init(statusCode: Int) {
        self.init(url: anyURL(), statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}

// swiftlint:enable force_unwrapping
// swiftlint:enable force_try
