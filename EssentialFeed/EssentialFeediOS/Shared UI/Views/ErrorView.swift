import UIKit

public final class ErrorView: UIButton {
    var onHide: (() -> Void)?
    
    public var message: String? {
        get { return isVisible ? configuration?.title : nil }
        set { setMessageAnimated(newValue) }
    }

    private var isVisible: Bool {
        return alpha > .zero
    }
    
    private var titleAttributes: AttributeContainer {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.center
        
        return AttributeContainer([
            .font: UIFont.preferredFont(forTextStyle: .body),
            .paragraphStyle: paragraphStyle
        ])
    }
    
    public private(set) lazy var button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.numberOfLines = .zero
        button.titleLabel?.font = .systemFont(ofSize: 17)
        button.addTarget(self, action: #selector(hideMessageAnimated), for: .touchUpInside)
        return button
    }()
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        configure()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func configure() {
        var configuration = Configuration.plain()
        configuration.titlePadding = .zero
        configuration.baseForegroundColor = .white
        configuration.background.backgroundColor = .backgroundColor
        configuration.background.cornerRadius = .zero
        self.configuration = configuration
        addTarget(self, action: #selector(hideMessageAnimated), for: .touchUpInside)
        hideMessage()
    }
    
    private func configureButton() {
        addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            button.centerXAnchor.constraint(equalTo: centerXAnchor),
            button.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            button.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    private func setMessageAnimated(_ message: String?) {
        if let message {
            showMessageAnimated(message)
        } else {
            hideMessageAnimated()
        }
    }
    
    @objc
    private func hideMessageAnimated() {
        UIView.animate(
            withDuration: 0.25,
            animations: { self.alpha = .zero },
            completion: { completed in
                if completed {
                    self.hideMessage()
                }
            }
        )
    }
    
    private func hideMessage() {
        configuration?.attributedTitle = nil
        configuration?.contentInsets = .zero
        alpha = .zero
        onHide?()
    }
    
    private func showMessageAnimated(_ message: String) {
        configuration?.attributedTitle = AttributedString(message, attributes: titleAttributes)
        let inset: CGFloat = 8
        configuration?.contentInsets = NSDirectionalEdgeInsets(
            top: inset,
            leading: inset,
            bottom: inset,
            trailing: inset
        )
        
        UIView.animate(withDuration: 0.25) {
            self.alpha = 1
        }
    }
}

private extension UIColor {
    static var backgroundColor: Self {
        return Self(red: 0.99951404330000004, green: 0.41759261489999999, blue: 0.4154433012, alpha: 1)
    }
}
