import XCTest
@testable import SaturdayCore

final class PromptAssemblerTests: XCTestCase {
    private let system = "You are Saturday, a discreet conversation copilot."

    private func longTail(_ count: Int) -> [Utterance] {
        (0..<count).map { index in
            Utterance(start: Double(index) * 10, end: Double(index) * 10 + 8,
                      text: "Speaker said something moderately long about topic number \(index) here.")
        }
    }

    func testEverythingFitsWhenSmall() {
        let assembler = PromptAssembler()
        let output = assembler.assemble(.init(
            systemPrompt: system,
            focus: "budget review",
            summaryHead: "Earlier: intro chatter.",
            retrievedSpans: ["[01:00] The Q3 target is 12 million."],
            tail: longTail(3),
            question: "What was the Q3 target?"
        ))
        XCTAssertFalse(output.droppedSummary)
        XCTAssertEqual(output.droppedSpanCount, 0)
        XCTAssertEqual(output.trimmedTailCount, 0)
        XCTAssertTrue(output.prompt.contains("Session focus: budget review"))
        XCTAssertTrue(output.prompt.contains("Q3 target is 12 million"))
        XCTAssertTrue(output.prompt.contains("Question: What was the Q3 target?"))
    }

    func testBudgetIsRespectedUnderOverload() {
        let assembler = PromptAssembler(budget: .init(contextWindow: 4096, reservedForOutput: 600))
        let output = assembler.assemble(.init(
            systemPrompt: system,
            summaryHead: String(repeating: "Long summary sentence. ", count: 200),
            retrievedSpans: (0..<50).map { "Span \($0): " + String(repeating: "detail ", count: 30) },
            tail: longTail(400),
            question: "Summarize the discussion."
        ))
        XCTAssertLessThanOrEqual(output.estimatedTokens, assembler.budget.inputBudget + 50)
        // Something had to give.
        XCTAssertTrue(output.trimmedTailCount > 0 || output.droppedSpanCount > 0 || output.droppedSummary)
        // The question always survives.
        XCTAssertTrue(output.prompt.contains("Question: Summarize the discussion."))
    }

    func testTailTrimsOldestFirst() {
        // Budget small enough that only part of the tail fits.
        let assembler = PromptAssembler(budget: .init(contextWindow: 700, reservedForOutput: 200))
        let tail = longTail(30)
        let output = assembler.assemble(.init(systemPrompt: system, tail: tail, question: "What was just said?"))
        XCTAssertGreaterThan(output.trimmedTailCount, 0)
        // The newest utterance must be present; the oldest must be gone.
        XCTAssertTrue(output.prompt.contains("topic number 29"))
        XCTAssertFalse(output.prompt.contains("topic number 0 here"))
    }

    func testDropOrderSummaryBeforeQuestion() {
        // Tiny budget: spans and summary must drop, question must stay.
        let assembler = PromptAssembler(budget: .init(contextWindow: 300, reservedForOutput: 100))
        let output = assembler.assemble(.init(
            systemPrompt: system,
            summaryHead: String(repeating: "summary ", count: 100),
            retrievedSpans: [String(repeating: "span ", count: 300)],
            tail: [],
            question: "Ping?"
        ))
        XCTAssertTrue(output.droppedSummary)
        XCTAssertEqual(output.droppedSpanCount, 1)
        XCTAssertTrue(output.prompt.contains("Question: Ping?"))
    }

    func testTimestampRendering() {
        XCTAssertEqual(PromptAssembler.timestamp(0), "00:00")
        XCTAssertEqual(PromptAssembler.timestamp(65), "01:05")
        XCTAssertEqual(PromptAssembler.timestamp(3599), "59:59")
    }
}
