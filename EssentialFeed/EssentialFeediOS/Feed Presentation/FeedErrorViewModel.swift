import Foundation

struct FeedErrorViewModel {
    let message: String?
    
    static func noError() -> Self {
        return Self(message: nil)
    }
    
    static func error(message: String) -> Self {
        return Self(message: message)
    }
}
