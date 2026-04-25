import XCTest
@testable import PikaAI

final class SSELineParserTests: XCTestCase {
    func testIgnoresNonDataLines() {
        switch SSELineParser.parseLine("event: message") {
        case .ignore: break
        default: XCTFail("Expected ignore")
        }
    }

    func testIgnoresEmptyDataLines() {
        switch SSELineParser.parseLine("data:   ") {
        case .ignore: break
        default: XCTFail("Expected ignore")
        }
    }

    func testDetectsDoneLine() {
        switch SSELineParser.parseLine("data: [DONE]") {
        case .done: break
        default: XCTFail("Expected done")
        }
    }

    func testParsesPayloadLine() {
        switch SSELineParser.parseLine("data: {\"ok\":true}") {
        case .data(let payload):
            XCTAssertEqual(payload, "{\"ok\":true}")
        default:
            XCTFail("Expected data payload")
        }
    }

    func testChunkAccumulatorHandlesSplitBoundary() {
        var accumulator = SSEChunkAccumulator()
        let first = accumulator.consume("data: {\"a\":1")
        XCTAssertTrue(first.isEmpty)

        let second = accumulator.consume("}\n")
        XCTAssertEqual(second, [.data("{\"a\":1}")])
    }

    func testChunkAccumulatorFlushesRemainder() {
        var accumulator = SSEChunkAccumulator()
        _ = accumulator.consume("data: hello")
        XCTAssertEqual(accumulator.flushRemainder(), [.data("hello")])
    }
}
