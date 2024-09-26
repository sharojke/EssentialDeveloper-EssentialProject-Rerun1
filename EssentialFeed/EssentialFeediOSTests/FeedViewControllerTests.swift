import EssentialFeed
import UIKit
import XCTest

private final class LoaderSpy: FeedLoader {
    private var completions = [(LoadResult) -> Void]()
    
    var loadCallCount: Int {
        return completions.count
    }
    
    func load(completion: @escaping (LoadResult) -> Void) {
        completions.append(completion)
    }
    
    func completeFeedLoading(at index: Int = .zero) {
        completions[index](.success([]))
    }
}

final class FeedViewController: UITableViewController {
    private let loader: FeedLoader
    private var onViewIsAppearing: ((FeedViewController) -> Void)?
    
    init(loader: FeedLoader) {
        self.loader = loader
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        onViewIsAppearing = { viewController in
            viewController.refresh()
            viewController.onViewIsAppearing = nil
        }
    }
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        
        onViewIsAppearing?(self)
    }
    
    @objc
    private func refresh() {
        refreshControl?.beginRefreshing()
        loader.load { [weak self] _ in
            self?.stopRefreshing()
        }
    }
    
    private func stopRefreshing() {
        refreshControl?.endRefreshing()
    }
}

private final class FakeRefreshControl: UIRefreshControl {
    private var _isRefreshing = false
    
    override var isRefreshing: Bool { _isRefreshing }
    
    override func beginRefreshing() {
        _isRefreshing = true
    }
    
    override func endRefreshing() {
        _isRefreshing = false
    }
}

final class FeedViewControllerTests: XCTestCase {
    func test_init_doesNotLoadFeed() {
        let (_, loader) = makeSUT()
        
        XCTAssertEqual(loader.loadCallCount, .zero)
    }
    
    func test_viewIsAppearing_loadsFeed() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        
        XCTAssertEqual(loader.loadCallCount, 1)
    }
    
    func test_viewIsAppearing_hidesLoadingIndicatorOnLoadingCompletion() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading()
        
        XCTAssertFalse(sut.isShowingLoadingIndicator())
    }
    
    func test_userInitiatedFeedReload_loadsFeed() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(loader.loadCallCount, 2)
        
        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(loader.loadCallCount, 3)
    }
    
    func test_userInitiatedFeedReload_hidesLoadingIndicatorOnLoadingCompletion() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(at: 0)
        sut.simulateUserInitiatedFeedReload()
        loader.completeFeedLoading(at: 1)
        
        XCTAssertFalse(sut.isShowingLoadingIndicator())
    }
    
    func test_loadingIndicator_reactorsAccordinglyOnUsersInteractions() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        XCTAssertTrue(sut.isShowingLoadingIndicator())
        
        loader.completeFeedLoading(at: 0)
        sut.simulateUserInitiatedFeedReload()
        XCTAssertTrue(sut.isShowingLoadingIndicator())
        
        loader.completeFeedLoading(at: 1)
        sut.simulateAppearance()
        XCTAssertFalse(sut.isShowingLoadingIndicator())
    }
    
    // MARK: Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: FeedViewController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }
}

private extension UIRefreshControl {
    func simulatePullToRefresh() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .valueChanged)?.forEach { action in
                (target as NSObject).perform(Selector(action))
            }
        }
    }
}

private extension FeedViewController {
    func simulateAppearance() {
        if !isViewLoaded {
            loadViewIfNeeded()
            replaceRefreshControlWithFakeForiOS17Support()
        }
        
        beginAppearanceTransition(true, animated: false)
        endAppearanceTransition()
    }
    
    func simulateUserInitiatedFeedReload() {
        refreshControl?.simulatePullToRefresh()
    }
    
    func isShowingLoadingIndicator() -> Bool {
        return refreshControl?.isRefreshing == true
    }
    
    private func replaceRefreshControlWithFakeForiOS17Support() {
        let fake = FakeRefreshControl()
        
        refreshControl?.allTargets.forEach { target in
            refreshControl?.actions(forTarget: target, forControlEvent: .valueChanged)?.forEach { action in
                fake.addTarget(target, action: Selector(action), for: .valueChanged)
            }
        }
        
        refreshControl = fake
    }
}
