import Combine
import EssentialFeed
import EssentialFeediOS
import UIKit

// swiftlint:disable force_unwrapping

public enum CommentsUIComposer {
    private typealias PresentationAdapter = LoadResourcePresentationAdapter<[ImageComment], CommentsViewAdapter>
    
    public static func feedComposedWith(
        feedLoader: @escaping () -> AnyPublisher<[ImageComment], Error>
    ) -> ListViewController {
        let presentationAdapter = PresentationAdapter(loader: { feedLoader().dispatchOnMainThread() })
        let commentsController = makeCommentsViewController(
            title: ImageCommentsPresenter.title,
            onRefresh: presentationAdapter.loadResource
        )
        let commentsViewAdapter = CommentsViewAdapter(controller: commentsController)
        let resourcePresenter = LoadResourcePresenter<[ImageComment], CommentsViewAdapter>(
            resourceView: commentsViewAdapter,
            loadingView: WeakRefVirtualProxy(commentsController),
            errorView: WeakRefVirtualProxy(commentsController),
            mapper: { ImageCommentsPresenter.map($0) }
        )
        presentationAdapter.resourcePresenter = resourcePresenter
        return commentsController
    }
    
    private static func makeCommentsViewController(
        title: String,
        onRefresh: @escaping () -> Void
    ) -> ListViewController {
        let bundle = Bundle(for: ListViewController.self)
        let storyboard = UIStoryboard(name: "ImageComments", bundle: bundle)
        let controller = storyboard.instantiateInitialViewController { coder in
            return ListViewController(coder: coder)
        }!
        controller.onRefresh = onRefresh
        controller.title = title
        return controller
    }
}

// swiftlint:enable force_unwrapping
