import Foundation

// swiftlint:disable:next convenience_type
public final class ImageCommentsPresenter {
    public static var title: String {
        return NSLocalizedString(
            "IMAGE_COMMENTS_VIEW_TITLE",
            tableName: "ImageComments",
            bundle: Bundle(for: Self.self),
            comment: ""
        )
    }
    
    public static func map(_ imageComments: [ImageComment]) -> ImageCommentsViewModel {
        let formatter = RelativeDateTimeFormatter()
        let comments = imageComments.map { comment in
            let date = formatter.localizedString(for: comment.createdAt, relativeTo: Date())
            return ImageCommentViewModel(
                message: comment.message,
                date: date,
                username: comment.username
            )
        }
        
        return ImageCommentsViewModel(comments: comments)
    }
}
