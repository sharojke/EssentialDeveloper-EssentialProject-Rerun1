import Combine
import EssentialFeed
import EssentialFeediOS
import UIKit

// swiftlint:disable force_unwrapping

public enum CommentsUIComposer {
    private typealias PresentationAdapter = LoadResourcePresentationAdapter<[FeedImage], FeedViewAdapter>
    
    public static func feedComposedWith(
        feedLoader: @escaping () -> AnyPublisher<[FeedImage], Error>
    ) -> ListViewController {
        let presentationAdapter = PresentationAdapter(loader: { feedLoader().dispatchOnMainThread() })
        let feedController = makeFeedViewController(
            title: ImageCommentsPresenter.title,
            onRefresh: presentationAdapter.loadResource
        )
        let feedViewAdapter = FeedViewAdapter(
            controller: feedController,
            loader: { _ in Empty<Data, Error>().eraseToAnyPublisher() }
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
