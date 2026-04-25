import Foundation

enum SSELineParser {
    enum Event: Equatable {
        case ignore
        case done
        case data(String)
    }

    static func parseLine(_ line: String) -> Event {
        guard line.hasPrefix("data:") else { return .ignore }
        let payload = line.dropFirst(5).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !payload.isEmpty else { return .ignore }
        return payload == "[DONE]" ? .done : .data(String(payload))
    }
}

struct SSEChunkAccumulator {
    private var buffer = ""

    mutating func consume(_ chunk: String) -> [SSELineParser.Event] {
        buffer.append(chunk)
        var events: [SSELineParser.Event] = []

        while let newline = buffer.firstIndex(of: "\n") {
            var line = String(buffer[..<newline])
            if line.hasSuffix("\r") {
                line.removeLast()
            }
            buffer = String(buffer[buffer.index(after: newline)...])
            events.append(SSELineParser.parseLine(line))
        }
        return events
    }

    mutating func flushRemainder() -> [SSELineParser.Event] {
        guard !buffer.isEmpty else { return [] }
        defer { buffer.removeAll(keepingCapacity: false) }
        return [SSELineParser.parseLine(buffer)]
    }
}
