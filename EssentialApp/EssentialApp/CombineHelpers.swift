import Combine
import EssentialFeed
import Foundation

// swiftlint:disable file_types_order

public extension Paginated {
    var loadMorePublisher: (() -> AnyPublisher<Self, Error>)? {
        guard let loadMore else { return nil }
        
        return { Deferred { Future(loadMore) }.eraseToAnyPublisher() }
    }
    
    init(items: [Item], loadMorePublisher: (() -> AnyPublisher<Self, Error>)?) {
        let loadMore: ((@escaping LoadMoreCompletion) -> Void)? = loadMorePublisher.map { publisher in
            return { completion in
                publisher().subscribe(Subscribers.Sink(
                    receiveCompletion: { result in
                        if case let .failure(error) = result {
                            completion(.failure(error))
                        }
                    },
                    receiveValue: { result in
                        completion(.success(result))
                    }
                ))
            }
        }
        
        self.init(
            items: items,
            loadMore: loadMore
        )
    }
}

public extension HTTPClient {
    typealias Publisher = AnyPublisher<(Data, HTTPURLResponse), Error>
    
    func getPublisher(url: URL) -> Publisher {
        var task: HTTPClientTask?
        
        return Deferred {
            Future { completion in
                task = self.get(from: url, completion: completion)
            }
        }
        .handleEvents(receiveCancel: { task?.cancel() })
        .eraseToAnyPublisher()
    }
}

public extension LocalFeedLoader {
    typealias Publisher = AnyPublisher<[FeedImage], Error>
    
    func loadPublisher() -> Publisher {
        return Deferred {
            Future { completion in
                completion(Result { try self.load() })
            }
        }.eraseToAnyPublisher()
    }
}

private extension FeedCache {
    func saveIgnoringResult(_ feed: [FeedImage]) {
        try? save(feed)
    }
    
    func saveIgnoringResult(_ paginatedFeed: Paginated<FeedImage>) {
        saveIgnoringResult(paginatedFeed.items)
    }
}

extension Publisher {
    func caching(to cache: FeedCache) -> AnyPublisher<Output, Failure> where Output == [FeedImage] {
        return handleEvents(receiveOutput: cache.saveIgnoringResult).eraseToAnyPublisher()
    }
    
    func caching(to cache: FeedCache) -> AnyPublisher<Output, Failure> where Output == Paginated<FeedImage> {
        return handleEvents(receiveOutput: cache.saveIgnoringResult).eraseToAnyPublisher()
    }
}

extension Publisher {
    func fallback(
        to fallbackPublisher: @escaping () -> AnyPublisher<Output, Failure>
    ) -> AnyPublisher<Output, Failure> {
        return self.catch { _ in fallbackPublisher() }.eraseToAnyPublisher()
    }
}

extension Publisher {
    func dispatchOnMainQueue() -> AnyPublisher<Output, Failure> {
        return receive(on: DispatchQueue.immediateWhenOnMainScheduler).eraseToAnyPublisher()
    }
    
    func dispatchOnMainThread() -> AnyPublisher<Output, Failure> {
        receive(on: DispatchQueue.immediateWhenOnMainThreadScheduler).eraseToAnyPublisher()
    }
}

// MARK: - Main Queue

extension DispatchQueue {
    struct ImmediateWhenOnMainScheduler: Scheduler {
        // swiftlint:disable:next nesting
        typealias SchedulerTimeType = DispatchQueue.SchedulerTimeType
        // swiftlint:disable:next nesting
        typealias SchedulerOptions = DispatchQueue.SchedulerOptions
        
        static let shared = Self()
        
        private static let key = DispatchSpecificKey<UInt8>()
        private static let value = UInt8.max
        
        var now: SchedulerTimeType {
            return DispatchQueue.main.now
        }
        
        var minimumTolerance: SchedulerTimeType.Stride {
            return DispatchQueue.main.minimumTolerance
        }
        
        private init() {
            DispatchQueue.main.setSpecific(key: Self.key, value: Self.value)
        }
        
        func schedule(options: SchedulerOptions?, _ action: @escaping () -> Void) {
            // swiftlint:disable:next void_function_in_ternary
            isMainQueue() ? action() : DispatchQueue.main.schedule(options: options, action)
        }
        
        func schedule(
            after date: SchedulerTimeType,
            tolerance: SchedulerTimeType.Stride,
            options: SchedulerOptions?,
            _ action: @escaping () -> Void
        ) {
            DispatchQueue.main.schedule(after: date, tolerance: tolerance, options: options, action)
        }
        
        func schedule(
            after date: SchedulerTimeType,
            interval: SchedulerTimeType.Stride,
            tolerance: SchedulerTimeType.Stride,
            options: SchedulerOptions?,
            _ action: @escaping () -> Void
        ) -> any Cancellable {
            DispatchQueue.main.schedule(
                after: date,
                interval: interval,
                tolerance: tolerance,
                options: options,
                action
            )
        }
        
        private func isMainQueue() -> Bool {
            return DispatchQueue.getSpecific(key: Self.key) == Self.value
        }
    }
    
    static var immediateWhenOnMainScheduler: ImmediateWhenOnMainScheduler {
        return ImmediateWhenOnMainScheduler.shared
    }
}

// MARK: - Main Thread

extension DispatchQueue {
    struct ImmediateWhenOnMainThreadScheduler: Scheduler {
        // swiftlint:disable:next nesting
        typealias SchedulerTimeType = DispatchQueue.SchedulerTimeType
        // swiftlint:disable:next nesting
        typealias SchedulerOptions = DispatchQueue.SchedulerOptions
        
        var now: SchedulerTimeType {
            DispatchQueue.main.now
        }
        
        var minimumTolerance: SchedulerTimeType.Stride {
            DispatchQueue.main.minimumTolerance
        }
        
        func schedule(options: SchedulerOptions?, _ action: @escaping () -> Void) {
            guard Thread.isMainThread else {
                return DispatchQueue.main.schedule(options: options, action)
            }
            
            action()
        }
        
        func schedule(
            after date: SchedulerTimeType,
            tolerance: SchedulerTimeType.Stride,
            options: SchedulerOptions?,
            _ action: @escaping () -> Void
        ) {
            DispatchQueue.main.schedule(after: date, tolerance: tolerance, options: options, action)
        }
        
        func schedule(
            after date: SchedulerTimeType,
            interval: SchedulerTimeType.Stride,
            tolerance: SchedulerTimeType.Stride,
            options: SchedulerOptions?,
            _ action: @escaping () -> Void
        ) -> Cancellable {
            DispatchQueue.main.schedule(
                after: date,
                interval: interval,
                tolerance: tolerance,
                options: options,
                action
            )
        }
    }
    
    static var immediateWhenOnMainThreadScheduler: ImmediateWhenOnMainThreadScheduler {
        return ImmediateWhenOnMainThreadScheduler()
    }
}

public extension FeedImageDataLoader {
    typealias Publisher = AnyPublisher<Data, Error>
    
    func loadImageDataPublisher(from url: URL) -> Publisher {
        return Deferred {
            return Future { completion in
                completion(Result { try self.loadImageData(from: url) })
            }
        }
        .eraseToAnyPublisher()
    }
}

private extension FeedImageDataCache {
    func saveIgnoringResult(_ data: Data, for url: URL) {
        try? save(data, for: url)
    }
}

extension Publisher where Output == Data {
    func caching(to cache: FeedImageDataCache, using url: URL) -> AnyPublisher<Output, Failure> {
        return handleEvents(receiveOutput: { data in
            cache.saveIgnoringResult(data, for: url)
        }).eraseToAnyPublisher()
    }
}

typealias AnyDispatchQueueScheduler = AnyScheduler<DispatchQueue.SchedulerTimeType, DispatchQueue.SchedulerOptions>

extension AnyDispatchQueueScheduler {
    static var immediateOnMainThread: Self {
        return DispatchQueue.immediateWhenOnMainThreadScheduler.eraseToAnyScheduler()
    }
}

extension Scheduler {
    func eraseToAnyScheduler() -> AnyScheduler<SchedulerTimeType, SchedulerOptions> {
        return AnyScheduler(self)
    }
}

// Created by copying the `AnyPublisher` and changing the implementation by conforming to `Scheduler`
struct AnyScheduler<SchedulerTimeType: Strideable, SchedulerOptions>: Scheduler
where SchedulerTimeType.Stride: SchedulerTimeIntervalConvertible {
    private let _now: () -> SchedulerTimeType
    private let _minimumTolerance: () -> SchedulerTimeType.Stride
    private let _schedule: (SchedulerOptions?, @escaping () -> Void) -> Void
    private let _scheduleAfter: (
        SchedulerTimeType,
        SchedulerTimeType.Stride,
        SchedulerOptions?,
        @escaping () -> Void
    ) -> Void
    private let _scheduleAfterInterval: (
        SchedulerTimeType,
        SchedulerTimeType.Stride,
        SchedulerTimeType.Stride,
        SchedulerOptions?,
        @escaping () -> Void
    ) -> Cancellable
    
    var now: SchedulerTimeType {
        return _now()
    }
    
    var minimumTolerance: SchedulerTimeType.Stride {
        return _minimumTolerance()
    }
    
    init<S>(_ scheduler: S)
    where SchedulerTimeType == S.SchedulerTimeType, SchedulerOptions == S.SchedulerOptions, S: Scheduler {
        _now = { scheduler.now }
        _minimumTolerance = { scheduler.minimumTolerance }
        _schedule = scheduler.schedule(options:_:)
        _scheduleAfter = scheduler.schedule(after:tolerance:options:_:)
        _scheduleAfterInterval = scheduler.schedule(after:interval:tolerance:options:_:)
    }
    
    func schedule(options: SchedulerOptions?, _ action: @escaping () -> Void) {
        _schedule(options, action)
    }
    
    func schedule(
        after date: SchedulerTimeType,
        tolerance: SchedulerTimeType.Stride,
        options: SchedulerOptions?,
        _ action: @escaping () -> Void
    ) {
        _scheduleAfter(date, tolerance, options, action)
    }
    
    func schedule(
        after date: SchedulerTimeType,
        interval: SchedulerTimeType.Stride,
        tolerance: SchedulerTimeType.Stride,
        options: SchedulerOptions?,
        _ action: @escaping () -> Void
    ) -> Cancellable {
        _scheduleAfterInterval(date, interval, tolerance, options, action)
    }
}

// swiftlint:enable file_types_order
