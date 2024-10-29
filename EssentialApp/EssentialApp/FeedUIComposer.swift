import Combine
import EssentialFeed
import EssentialFeediOS
import UIKit

// swiftlint:disable force_unwrapping

public enum FeedUIComposer {
    public static func feedComposedWith(
        feedLoader: @escaping () -> AnyPublisher<[FeedImage], Error>,
        imageLoader: @escaping (URL) -> FeedImageDataLoader.Publisher
    ) -> FeedViewController {
        let presentationAdapter = FeedLoadingPresentationAdapter(
            feedLoader: { feedLoader().dispatchOnMainQueue() }
        )
        let feedController = makeFeedViewController(
            delegate: presentationAdapter,
            title: FeedPresenter.title
        )
        let feedViewAdapter = FeedViewAdapter(
            controller: feedController,
            loader: { imageLoader($0).dispatchOnMainQueue() }
        )
        let feedPresenter = FeedPresenter(
            feedView: feedViewAdapter,
            loadingView: WeakRefVirtualProxy(feedController),
            errorView: WeakRefVirtualProxy(feedController)
        )
        presentationAdapter.feedPresenter = feedPresenter
        return feedController
    }
    
    private static func makeFeedViewController(
        delegate: FeedViewControllerDelegate,
        title: String
    ) -> FeedViewController {
        let bundle = Bundle(for: FeedViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let controller = storyboard.instantiateInitialViewController { coder in
            return FeedViewController(coder: coder, delegate: delegate)
        }!
        controller.title = title
        return controller
    }
}

// swiftlint:enable force_unwrapping
