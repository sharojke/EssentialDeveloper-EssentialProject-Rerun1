import Foundation

// swiftlint:disable:next convenience_type
public final class FeedPresenter {
    public static var title: String {
        return NSLocalizedString(
            "FEED_VIEW_TITLE",
            tableName: "Feed",
            bundle: Bundle(for: Self.self),
            comment: ""
        )
    }
}
