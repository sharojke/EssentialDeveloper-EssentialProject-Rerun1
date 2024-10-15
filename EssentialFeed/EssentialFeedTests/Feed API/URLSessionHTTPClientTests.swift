import EssentialFeed
import XCTest

// swiftlint:disable force_unwrapping
// swiftlint:disable implicitly_unwrapped_optional
// swiftlint:disable large_tuple

final class URLSessionHTTPClientTests: XCTestCase {
    override final class func tearDown() {
        super.tearDown()
        
        URLProtocolStub.removeStub()
    }
    
    func test_getFromURL_performsGETRequestWithURL() {
        let url = anyURL()
        
        let exp = expectation(description: "Wait for request")
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        makeSUT().get(from: url) { _ in }
        
        wait(for: [exp], timeout: 1)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let expectedError = anyNSError()
        let receivedError = resultError((data: nil, response: nil, error: expectedError)) as? NSError
        
        XCTAssertEqual(receivedError?.code, expectedError.code)
        XCTAssertEqual(receivedError?.domain, expectedError.domain)
    }
    
    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        XCTAssertNotNil(resultError((data: nil, response: nil, error: nil)))
        XCTAssertNotNil(resultError((data: nil, response: nonHTTPURLResponse(), error: nil)))
        XCTAssertNotNil(resultError((data: anyData(), response: nil, error: nil)))
        XCTAssertNotNil(resultError((data: anyData(), response: nil, error: anyError())))
        XCTAssertNotNil(resultError((data: nil, response: nonHTTPURLResponse(), error: anyError())))
        XCTAssertNotNil(resultError((data: nil, response: anyHTTPURLResponse(), error: anyError())))
        XCTAssertNotNil(resultError((data: anyData(), response: nonHTTPURLResponse(), error: anyError())))
        XCTAssertNotNil(resultError((data: anyData(), response: anyHTTPURLResponse(), error: anyError())))
        XCTAssertNotNil(resultError((data: anyData(), response: nonHTTPURLResponse(), error: nil)))
    }
    
    func test_getFromURL_succeedsOnHTTPURLResponseWithData() {
        let expectedData = anyData()
        let expectedResponse = anyHTTPURLResponse()
        
        let receivedValues = resultValues((data: expectedData, response: expectedResponse, error: nil))
        
        XCTAssertEqual(receivedValues?.data, expectedData)
        XCTAssertEqual(receivedValues?.response.url, expectedResponse.url)
        XCTAssertEqual(receivedValues?.response.statusCode, expectedResponse.statusCode)
    }
    
    func test_getFromURL_succeedsWithEmptyDataOnHTTPURLResponseWithNilData() {
        let expectedResponse = anyHTTPURLResponse()
        
        let receivedValues = resultValues((data: nil, response: expectedResponse, error: nil))
        
        let emptyData = Data()
        XCTAssertEqual(receivedValues?.data, emptyData)
        XCTAssertEqual(receivedValues?.response.url, expectedResponse.url)
        XCTAssertEqual(receivedValues?.response.statusCode, expectedResponse.statusCode)
    }
    
    func test_cancelGetFromURLTask_cancelsURLRequest() {
        var task: HTTPClientTask?
        URLProtocolStub.onStartLoading { task?.cancel() }
        
        let receivedError = resultError { task = $0 } as NSError?

        XCTAssertEqual(receivedError?.code, URLError.cancelled.rawValue)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> HTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        let sut = URLSessionHTTPClient(session: session)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func nonHTTPURLResponse() -> URLResponse {
        return URLResponse(
            url: anyURL(),
            mimeType: nil,
            expectedContentLength: .zero,
            textEncodingName: nil
        )
    }
    
    private func anyHTTPURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(
            url: anyURL(),
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
    }
    
    private func resultError(
        _ values: (data: Data?, response: URLResponse?, error: Error?)? = nil,
        taskHandler: (HTTPClientTask) -> Void = { _ in },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Error? {
        let result = result(values, taskHandler: taskHandler, file: file, line: line)

        switch result {
        case .failure(let error):
            return error
            
        default:
            XCTFail("Expected failure, got \(result) instead", file: file, line: line)
            return nil
        }
    }
    
    private func resultValues(
        _ values: (data: Data?, response: URLResponse?, error: Error?),
        file: StaticString = #file,
        line: UInt = #line
    ) -> (data: Data, response: HTTPURLResponse)? {
        let result = result(values, file: file, line: line)

        switch result {
        case let .success((receivedData, receivedResponse)):
            return (receivedData, receivedResponse)
            
        default:
            XCTFail("Expected success, got \(result) instead", file: file, line: line)
            return nil
        }
    }
    
    private func result(
        _ values: (data: Data?, response: URLResponse?, error: Error?)?,
        taskHandler: (HTTPClientTask) -> Void = { _ in },
        file: StaticString = #file,
        line: UInt = #line
    ) -> HTTPClient.GetResult {
        values.map { URLProtocolStub.stub(data: $0, response: $1, error: $2) }
        
        let sut = makeSUT(file: file, line: line)
        
        let exp = expectation(description: "Wait for get completion")
        var receivedResult: HTTPClient.GetResult!
        let task = sut.get(from: anyURL()) { result in
            receivedResult = result
            exp.fulfill()
        }
        taskHandler(task)
        
        wait(for: [exp], timeout: 3)
        return receivedResult
    }
}

// swiftlint:enable force_unwrapping
// swiftlint:enable implicitly_unwrapped_optional
// swiftlint:enable large_tuple
