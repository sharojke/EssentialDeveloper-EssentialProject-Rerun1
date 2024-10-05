import UIKit

extension UITableView {
    func dequeueReusableCell<T: UITableViewCell>() -> T {
        // swiftlint:disable:next force_cast
        return dequeueReusableCell(withIdentifier: String(describing: T.self)) as! T
    }
}
