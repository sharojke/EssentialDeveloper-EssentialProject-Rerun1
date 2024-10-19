import EssentialFeed
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

func uniqueFeed() -> [FeedImage] {
    let image = FeedImage(
        id: UUID(),
        description: "a description",
        location: "a location",
        url: URL(string: "http://a-url.com")!
    )
    return [image]
}

// swiftlint:enable force_unwrapping
