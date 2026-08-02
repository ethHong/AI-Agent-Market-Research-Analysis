import XCTest
@testable import SaturdayCore

final class ToolCallingTests: XCTestCase {
    private let specs = [
        ToolSpec(name: "create_event",
                 description: "Add a calendar event",
                 parameters: [
                    .init(name: "title", type: "string", required: true, description: "Event title"),
                    .init(name: "start", type: "string", required: true, description: "ISO8601 start"),
                    .init(name: "notes", type: "string", required: false, description: "Optional notes")
                 ]),
        ToolSpec(name: "web_lookup",
                 description: "Search the web",
                 parameters: [
                    .init(name: "query", type: "string", required: true, description: "Search terms")
                 ])
    ]

    func testParsesCleanJSON() throws {
        let parser = ToolCallParser(specs: specs)
        let call = try parser.parse(#"{"tool": "create_event", "arguments": {"title": "Lunch", "start": "2026-08-03T13:00:00Z"}}"#)
        XCTAssertEqual(call.name, "create_event")
        XCTAssertEqual(call.arguments["title"]?.stringValue, "Lunch")
    }

    func testParsesJSONSurroundedByProse() throws {
        let parser = ToolCallParser(specs: specs)
        let output = """
        Sure — I'll set that up.
        ```json
        {"tool": "web_lookup", "arguments": {"query": "EBITDA definition"}}
        ```
        Done.
        """
        let call = try parser.parse(output)
        XCTAssertEqual(call.name, "web_lookup")
        XCTAssertEqual(call.arguments["query"]?.stringValue, "EBITDA definition")
    }

    func testNestedBracesInsideStringsSurvive() throws {
        let parser = ToolCallParser(specs: specs)
        let call = try parser.parse(#"{"tool": "create_event", "arguments": {"title": "Review {draft}", "start": "2026-08-03T09:00:00Z"}}"#)
        XCTAssertEqual(call.arguments["title"]?.stringValue, "Review {draft}")
    }

    func testUnknownToolThrows() {
        let parser = ToolCallParser(specs: specs)
        XCTAssertThrowsError(try parser.parse(#"{"tool": "delete_everything", "arguments": {}}"#)) { error in
            XCTAssertEqual(error as? ToolCallParseError, .unknownTool("delete_everything"))
        }
    }

    func testMissingRequiredArgumentThrows() {
        let parser = ToolCallParser(specs: specs)
        XCTAssertThrowsError(try parser.parse(#"{"tool": "create_event", "arguments": {"title": "Lunch"}}"#)) { error in
            XCTAssertEqual(error as? ToolCallParseError,
                           .missingRequiredArgument(tool: "create_event", argument: "start"))
        }
    }

    func testNoJSONThrows() {
        let parser = ToolCallParser(specs: specs)
        XCTAssertThrowsError(try parser.parse("I don't need a tool for that.")) { error in
            XCTAssertEqual(error as? ToolCallParseError, .noJSONObjectFound)
        }
    }

    func testNumberAndBoolArguments() throws {
        let specsWithExtras = [ToolSpec(name: "set_timer", description: "t",
                                        parameters: [.init(name: "minutes", type: "number", required: true, description: "")])]
        let parser = ToolCallParser(specs: specsWithExtras)
        let call = try parser.parse(#"{"tool": "set_timer", "arguments": {"minutes": 15, "repeat": false}}"#)
        XCTAssertEqual(call.arguments["minutes"]?.numberValue, 15)
        if case .bool(let flag)? = call.arguments["repeat"] {
            XCTAssertFalse(flag)
        } else {
            XCTFail("expected bool")
        }
    }
}
