import EssentialFeed
import XCTest

final class ImageCommentsPresenterTests: XCTestCase {
    func test_title_isLocalized() {
        XCTAssertEqual(ImageCommentsPresenter.title, localized("IMAGE_COMMENTS_VIEW_TITLE"))
    }
    
    func test_map_createsViewModel() {
        let now = Date()
        let calendar = Calendar(identifier: .gregorian)
        let locale = Locale(identifier: "en_US_POSIX")
        
        let comment1 = uniqueImageComment(createdAt: now.adding(minutes: -5, calendar: calendar))
        let comment2 = uniqueImageComment(createdAt: now.adding(days: -1, calendar: calendar))
        let comments = [comment1, comment2]
        
        let viewModel = ImageCommentsPresenter.map(
            comments,
            currentDate: now,
            calendar: calendar,
            locale: locale
        )
        
        XCTAssertEqual(
            viewModel.comments,
            [
                ImageCommentViewModel(
                    message: comment1.message,
                    date: "5 minutes ago",
                    username: comment1.username
                ),
                ImageCommentViewModel(
                    message: comment2.message,
                    date: "1 day ago",
                    username: comment2.username
                )
            ]
        )
    }
    
    // MARK: Helpers
    
    private func localized(
        _ key: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> String {
        let table = "ImageComments"
        let bundle = Bundle(for: ImageCommentsPresenter.self)
        let value = bundle.localizedString(forKey: key, value: nil, table: table)
        if value == key {
            XCTFail("Missing localized string for key: \(key) in table: \(table)", file: file, line: line)
        }
        return value
    }
    
    private func uniqueImageComment(createdAt: Date) -> ImageComment {
        return ImageComment(
            id: UUID(),
            message: "a message",
            createdAt: createdAt,
            username: "a username"
        )
    }
}
