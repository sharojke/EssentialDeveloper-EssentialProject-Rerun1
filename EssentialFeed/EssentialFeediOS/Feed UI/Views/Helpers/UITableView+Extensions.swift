import UIKit

extension UITableView {
    func dequeueReusableCell<T: UITableViewCell>() -> T {
        // swiftlint:disable:next force_cast
        return dequeueReusableCell(withIdentifier: String(describing: T.self)) as! T
    }
    
    func sizeHeaderToFit() {
        guard let header = tableHeaderView else { return }
        
        let size = header.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        let needsFrameUpdate = header.frame.height != size.height
        guard needsFrameUpdate else { return }
        
        header.frame.size.height = size.height
        tableHeaderView = header
    }
}
