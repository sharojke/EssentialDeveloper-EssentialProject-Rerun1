import Foundation

public struct ResourceErrorViewModel {
    public let message: String?
    
    public init(message: String?) {
        self.message = message
    }
    
    static func noError() -> Self {
        return Self(message: nil)
    }
    
    static func error(message: String) -> Self {
        return Self(message: message)
    }
}
