import UIKit

public final class FeedImageCell: UITableViewCell {
    var onRetry: (() -> Void)?
    var onReuse: (() -> Void)?
    
    @IBOutlet public private(set) var locationContainer: UIView!
    @IBOutlet public private(set) var locationLabel: UILabel!
    @IBOutlet public private(set) var descriptionLabel: UILabel!
    @IBOutlet public private(set) var feedImageContainer: UIView!
    @IBOutlet public private(set) var feedImageView: UIImageView!
    @IBOutlet public private(set) var feedImageRetryButton: UIButton!

    @IBAction private func retryButtonTapped() {
        onRetry?()
    }
    
    override public func prepareForReuse() {
        super.prepareForReuse()
        
        onReuse?()
    }
}
