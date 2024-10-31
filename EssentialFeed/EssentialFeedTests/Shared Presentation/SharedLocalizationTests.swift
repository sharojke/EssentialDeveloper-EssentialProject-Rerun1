import EssentialFeed
import XCTest

private final class DummyView: ResourceView {    
    func display(_ viewModel: Any) {}
}

final class SharedLocalizationTests: XCTestCase {
    private typealias LocalizedBundle = (bundle: Bundle, localization: String)
    
    func test_localizedStrings_haveKeysAndValuesForAllSupportedLocalizations() {
        let table = "Shared"
        let bundle = Bundle(for: LoadResourcePresenter<Any, DummyView>.self)
        
        assertLocalizedKeyAndValuesExist(in: bundle, table)
    }
}
