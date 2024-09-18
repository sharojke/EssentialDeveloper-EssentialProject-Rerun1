import EssentialFeed
import Foundation

// swiftlint:disable force_unwrapping

var calendar: Calendar {
    return Calendar(identifier: .gregorian)
}

func uniqueImage() -> FeedImage {
    return FeedImage(
        id: UUID(),
        description: "a description",
        location: "a location",
        url: anyURL()
    )
}

func uniqueFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
    let feed = [uniqueImage(), uniqueImage()]
    let local = feed.map { image in
        LocalFeedImage(
            id: image.id,
            description: image.description,
            location: image.location,
            url: image.url
        )
    }
    return (feed, local)
}

extension Date {
    private var feedCacheMaxAgeInDays: Int { 7 }
    
    func minusFeedCacheMaxAge(calendar: Calendar = Calendar(identifier: .gregorian)) -> Date {
        return adding(days: -feedCacheMaxAgeInDays, calendar: calendar)
    }
    
    func adding(seconds: Int, calendar: Calendar = Calendar(identifier: .gregorian)) -> Date {
        return calendar.date(byAdding: .second, value: seconds, to: self)!
    }
    
    private func adding(days: Int, calendar: Calendar = Calendar(identifier: .gregorian)) -> Date {
        return calendar.date(byAdding: .day, value: days, to: self)!
    }
}

// swiftlint:enable force_unwrapping
