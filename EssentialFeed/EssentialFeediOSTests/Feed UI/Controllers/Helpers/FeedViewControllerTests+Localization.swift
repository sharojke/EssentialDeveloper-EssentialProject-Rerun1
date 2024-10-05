import EssentialFeediOS
import Foundation
import XCTest

extension FeedViewControllerTests {
    func assertThat(
        _ string: String?,
        isLocalizationForKey key: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let string else {
            return XCTFail("Passed value is nil for key \"\(key)\"", file: file, line: line)
        }
        
        let table = "Feed"
        let bundle = Bundle(for: FeedViewController.self)
        let localizedString = bundle.localizedString(forKey: key, value: nil, table: table)
        
        if localizedString == key {
            XCTFail(
                "Missing localized string for key: \(key) in table: \(table)",
                file: file,
                line: line
            )
        } else {
            XCTAssertEqual(
                string,
                localizedString,
                "Expected localized \"\(string)\" for key \"\(key)\" in table \"\(table)\", got \"\(localizedString)\" instead",
                file: file,
                line: line
            )
        }
    }
}
