import Foundation

// swiftlint:disable force_unwrapping

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

// swiftlint:enable force_unwrapping
