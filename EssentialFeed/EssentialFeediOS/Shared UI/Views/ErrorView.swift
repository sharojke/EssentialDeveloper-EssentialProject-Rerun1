import UIKit

public final class ErrorView: UIView {
    public var message: String? {
        return isVisible ? button.title(for: .normal) : nil
    }

    private var isVisible: Bool {
        return alpha > .zero
    }
    
    @IBOutlet public private(set) var button: UIButton!
    
    @IBAction func hideMessage() {
        UIView.animate(
            withDuration: 0.25,
            animations: { self.alpha = .zero },
            completion: { completed in
                guard completed else { return }
                
                self.button.setTitle(nil, for: .normal)
            }
        )
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()

        button.setTitle(nil, for: .normal)
        alpha = 0
    }

    func show(message: String) {
        button.setTitle(message, for: .normal)
        
        UIView.animate(withDuration: 0.25) {
            self.alpha = 1
        }
    }
}
