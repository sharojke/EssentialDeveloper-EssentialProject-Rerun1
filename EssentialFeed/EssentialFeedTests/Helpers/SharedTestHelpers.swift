import Foundation

// swiftlint:disable force_unwrapping

func anyNSError() -> NSError {
    return NSError(domain: "", code: .zero)
}

func anyURL() -> URL {
    return URL(string: "http://any-url.com")!
}

// swiftlint:enable force_unwrapping
