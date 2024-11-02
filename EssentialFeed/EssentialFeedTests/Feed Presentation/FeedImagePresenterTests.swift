import EssentialFeed
import XCTest

final class FeedImagePresenterTests: XCTestCase {
    func test_map_createdViewModel() {
        let image = uniqueImage()
        
        let viewModel = FeedImagePresenter.map(image)
        
        XCTAssertEqual(viewModel.description, image.description)
        XCTAssertEqual(viewModel.location, image.location)
    }
}
