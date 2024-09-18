import Foundation

enum FeedCachePolicy {
    private static var maxCacheAgeInDays: Int { 7 }
    
    static func validate(
        _ timestamp: Date,
        against date: Date,
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> Bool {
        guard let maxAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
            return false
        }
        
        return date < maxAge
    }
}
