import Combine
import EssentialFeed
import EssentialFeediOS
import UIKit

// swiftlint:disable force_unwrapping

public enum FeedUIComposer {
    private typealias PresentationAdapter = LoadResourcePresentationAdapter<[FeedImage], FeedViewAdapter>
    
    public static func feedComposedWith(
        feedLoader: @escaping () -> AnyPublisher<[FeedImage], Error>,
        imageLoader: @escaping (URL) -> FeedImageDataLoader.Publisher
    ) -> ListViewController {
        let presentationAdapter = PresentationAdapter(loader: { feedLoader().dispatchOnMainQueue() })
        let feedController = makeFeedViewController(
            title: FeedPresenter.title,
            onRefresh: presentationAdapter.loadResource
        )
        let feedViewAdapter = FeedViewAdapter(
            controller: feedController,
            loader: { imageLoader($0).dispatchOnMainQueue() }
        )
        let resourcePresenter = LoadResourcePresenter<[FeedImage], FeedViewAdapter>(
            resourceView: feedViewAdapter,
            loadingView: WeakRefVirtualProxy(feedController),
            errorView: WeakRefVirtualProxy(feedController),
            mapper: FeedPresenter.map
        )
        presentationAdapter.resourcePresenter = resourcePresenter
        return feedController
    }
    
    private static func makeFeedViewController(
        title: String,
        onRefresh: @escaping () -> Void
    ) -> ListViewController {
        let bundle = Bundle(for: ListViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let controller = storyboard.instantiateInitialViewController { coder in
            return ListViewController(coder: coder)
        }!
        controller.onRefresh = onRefresh
        controller.title = title
        return controller
    }
}

// swiftlint:enable force_unwrapping
