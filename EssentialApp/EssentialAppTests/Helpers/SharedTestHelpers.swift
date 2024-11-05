import EssentialFeed
import Foundation

// swiftlint:disable force_unwrapping

final class DummyView: ResourceView {
    func display(_ viewModel: Any) {}
}

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

func executeRunLoopToCleanUpReferences() {
    RunLoop.current.run(until: Date())
}

var loadError: String {
    return LoadResourcePresenter<Any, DummyView>.loadError
}

var feedTitle: String {
    return FeedPresenter.title
}

var commentsTitle: String {
    return ImageCommentsPresenter.title
}

// swiftlint:enable force_unwrapping
