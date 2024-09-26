import EssentialFeed
import XCTest

final class LoaderSpy {
    let loadCallCount = 0
}


final class FeedViewController {
    private let loader: LoaderSpy
    
    init(loader: LoaderSpy) {
        self.loader = loader
    }
}

final class FeedViewControllerTests: XCTestCase {
    func test_init_doesNotLoadFeed() {
        let loader = LoaderSpy()
        _ = FeedViewController(loader: loader)
        
        XCTAssertEqual(loader.loadCallCount, .zero)
    }
}
