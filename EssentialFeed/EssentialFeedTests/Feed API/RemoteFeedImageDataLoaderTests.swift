import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping

private final class HTTPClientSpy: HTTPClient {
    private struct Task: HTTPClientTask {
        private let onCancel: () -> Void
        
        init(onCancel: @escaping () -> Void) {
            self.onCancel = onCancel
        }
        
        func cancel() {
            onCancel()
        }
    }
    
    private var messages = [(url: URL, completion: (GetResult) -> Void)]()
    private(set) var cancelledURLs = [URL]()
    
    var requestedURLs: [URL] {
        return messages.map { $0.url }
    }
    
    func get(from url: URL, completion: @escaping (GetResult) -> Void) -> HTTPClientTask {
        messages.append((url, completion))
        return Task { [weak self] in
            self?.cancelledURLs.append(url)
        }
    }
    
    func complete(with error: Error, at index: Int = 0) {
        messages[index].completion(.failure(error))
    }
    
    func complete(with statusCode: Int, data: Data, at index: Int = 0) {
        let message = messages[index]
        let response = HTTPURLResponse(
            url: message.url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        message.completion(.success((data, response)))
    }
}

private final class HTTPTaskWrapper: FeedImageDataLoaderTask {
    private var completion: FeedImageDataLoader.LoadImageResultCompletion?
    var wrapped: HTTPClientTask?
    
    init(completion: @escaping FeedImageDataLoader.LoadImageResultCompletion) {
        self.completion = completion
    }
    
    func complete(with result: FeedImageDataLoader.LoadImageResult) {
        completion?(result)
    }
    
    func cancel() {
        preventFurtherCompletions()
        wrapped?.cancel()
        wrapped = nil
    }
    
    private func preventFurtherCompletions() {
        completion = nil
    }
}

final class RemoteFeedImageDataLoader: FeedImageDataLoader {
    public enum Error: Swift.Error {
        case invalidData
    }
    
    private let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }
    
    @discardableResult
    func loadImageData(
        from url: URL,
        completion: @escaping LoadImageResultCompletion
    ) -> FeedImageDataLoaderTask {
        let taskWrapper = HTTPTaskWrapper(completion: completion)
        let task = client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            
            let taskResult: FeedImageDataLoader.LoadImageResult
            defer { taskWrapper.complete(with: taskResult) }
            
            switch result {
            case let .success((data, response)):
                guard response.statusCode == 200,
                      !data.isEmpty else {
                    taskResult = .failure(Error.invalidData)
                    return
                }
                
                taskResult = .success(data)
                
            case .failure(let error):
                taskResult = .failure(error)
            }
        }
        taskWrapper.wrapped = task
        return taskWrapper
    }
}

final class RemoteFeedImageDataLoaderTests: XCTestCase {
    func test_init_doesNotPerformAnyURLRequest() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_loadImageDataFromURL_requestsDataFromURL() {
        let (sut, client) = makeSUT()
        let url = anyURL()
        
        sut.loadImageData(from: url) { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadImageDataFromURLTwice_requestsDataFromURLTwice() {
        let (sut, client) = makeSUT()
        let url = anyURL()
        
        sut.loadImageData(from: url) { _ in }
        sut.loadImageData(from: url) { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_loadImageDataFromURL_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        let error = anyNSError()
        
        expect(sut, toCompleteWith: .failure(error)) {
            client.complete(with: error)
        }
    }
    
    func test_loadImageDataFromURL_deliversInvalidDataErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        let codes = [199, 201, 300, 400, 500]
        
        codes.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: failure(.invalidData)) {
                client.complete(with: code, data: anyData(), at: index)
            }
        }
    }
    
    func test_loadImageDataFromURL_deliversInvalidDataErrorOn200HTTPResponseWithEmptyData() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: failure(.invalidData)) {
            client.complete(with: 200, data: Data())
        }
    }
    
    func test_loadImageDataFromURL_deliversReceivedNonEmptyDataOn200HTTPResponse() {
        let (sut, client) = makeSUT()
        let nonEmptyData = anyData()
        
        expect(sut, toCompleteWith: .success(nonEmptyData)) {
            client.complete(with: 200, data: nonEmptyData)
        }
    }
    
    func test_loadImageDataFromURL_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let client = HTTPClientSpy()
        var sut: RemoteFeedImageDataLoader? = RemoteFeedImageDataLoader(client: client)
        
        var capturedResults = [FeedImageDataLoader.LoadImageResult]()
        sut?.loadImageData(from: anyURL()) { capturedResults.append($0) }
        
        sut = nil
        client.complete(with: anyError())
        
        XCTAssertTrue(capturedResults.isEmpty)
    }
    
    func test_cancelLoadImageDataURLTask_cancelsClientURLRequest() {
        let (sut, client) = makeSUT()
        let url = anyURL()
        
        let task = sut.loadImageData(from: url) { _ in }
        XCTAssertTrue(client.cancelledURLs.isEmpty)
        
        task.cancel()
        XCTAssertEqual(client.cancelledURLs, [url])
    }
    
    func test_loadImageDataFromURL_doesNotDeliverResultAfterCancellingTask() {
        let (sut, client) = makeSUT()
        let data = anyData()
        
        var receivedResults = [FeedImageDataLoader.LoadImageResult]()
        let task = sut.loadImageData(from: anyURL()) { receivedResults.append($0) }
        task.cancel()
        
        client.complete(with: 400, data: anyData())
        client.complete(with: 200, data: data)
        client.complete(with: anyError())
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    // MARK: Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: RemoteFeedImageDataLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedImageDataLoader(client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }
    
    private func expect(
        _ sut: RemoteFeedImageDataLoader,
        toCompleteWith expectedResult: FeedImageDataLoader.LoadImageResult,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let url = anyURL()
        let exp = expectation(description: "Wait for client completion")
        
        sut.loadImageData(from: url) { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedData), .success(expectedData)):
                XCTAssertEqual(
                    receivedData,
                    expectedData,
                    "Expected \(expectedData), got \(receivedData) instead",
                    file: file,
                    line: line
                )
                
            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(
                    receivedError.domain,
                    expectedError.domain,
                    "Expected \(receivedError.domain), got \(receivedError.domain) instead",
                    file: file,
                    line: line
                )
                XCTAssertEqual(
                    receivedError.code,
                    receivedError.code,
                    "Expected \(receivedError.code), got \(receivedError.code) instead",
                    file: file,
                    line: line
                )
                
            default:
                XCTFail("Expected \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1)
    }
    
    private func failure(_ error: RemoteFeedImageDataLoader.Error) -> FeedImageDataLoader.LoadImageResult {
        return .failure(error)
    }
}

// swiftlint:enable force_unwrapping
