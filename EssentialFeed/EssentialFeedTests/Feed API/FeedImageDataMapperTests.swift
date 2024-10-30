import EssentialFeed
import XCTest

final class FeedImageDataMapperTests: XCTestCase {
    func test_map_throwsInvalidDataErrorOnNon200HTTPResponse() throws {
        let codes = [199, 201, 300, 400, 500]
        
        try codes.forEach { code in
            XCTAssertThrowsError(
                try FeedImageDataMapper.map(data: anyData(), response: HTTPURLResponse(statusCode: code))
            )
        }
    }
    
    func test_map_throwsInvalidDataErrorOn200HTTPResponseWithEmptyData() {
        let emptyData = Data()
        
        XCTAssertThrowsError(
            try FeedImageDataMapper.map(data: emptyData, response: HTTPURLResponse(statusCode: 200))
        )
    }
    
    func test_map_throwsReceivedNonEmptyDataOn200HTTPResponse() throws {
        let nonEmptyData = anyData()
        
        let result = try FeedImageDataMapper.map(
            data: nonEmptyData,
            response: HTTPURLResponse(statusCode: 200)
        )
        
        XCTAssertEqual(result, nonEmptyData)
    }
}
