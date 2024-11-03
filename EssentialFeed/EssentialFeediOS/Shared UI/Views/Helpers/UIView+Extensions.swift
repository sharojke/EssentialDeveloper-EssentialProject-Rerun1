import UIKit

extension UIView {
    func makeContainer() -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        containerView.addSubview(self)
        
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            topAnchor.constraint(equalTo: containerView.topAnchor),
            centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        return containerView
    }
}
