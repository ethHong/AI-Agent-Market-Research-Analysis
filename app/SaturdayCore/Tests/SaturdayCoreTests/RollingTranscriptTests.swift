import XCTest
@testable import SaturdayCore

final class RollingTranscriptTests: XCTestCase {
    private func utterance(_ text: String, at time: TimeInterval) -> Utterance {
        Utterance(start: time, end: time + 3, text: text)
    }

    func testNoCompactionUnderBudget() {
        var transcript = RollingTranscript(config: .init(tailTokenBudget: 200, compactionSlack: 1.5))
        for index in 0..<5 {
            transcript.append(utterance("short line \(index)", at: Double(index) * 5))
        }
        XCTAssertTrue(transcript.compactionBatch().isEmpty)
    }

    func testCompactionTriggersAboveSlackThreshold() {
        var transcript = RollingTranscript(config: .init(tailTokenBudget: 50, compactionSlack: 1.5))
        // Push well past 75 estimated tokens.
        for index in 0..<30 {
            transcript.append(utterance("this is a reasonably long spoken sentence number \(index)", at: Double(index) * 5))
        }
        let batch = transcript.compactionBatch()
        XCTAssertFalse(batch.isEmpty)
        // Batch must be the OLDEST utterances.
        XCTAssertEqual(batch.first?.text, transcript.tail.first?.text)
        // What remains after compaction must fit the tail budget.
        let keptTokens = TokenEstimator.estimate(Array(transcript.tail.dropFirst(batch.count)))
        XCTAssertLessThanOrEqual(keptTokens, 50)
    }

    func testApplyCompactionUpdatesTailAndSummary() {
        var transcript = RollingTranscript(config: .init(tailTokenBudget: 50, compactionSlack: 1.5))
        for index in 0..<30 {
            transcript.append(utterance("this is a reasonably long spoken sentence number \(index)", at: Double(index) * 5))
        }
        let batch = transcript.compactionBatch()
        let originalTailCount = transcript.tail.count
        transcript.applyCompaction(newSummaryHead: "They discussed sentences.", compactedCount: batch.count)
        XCTAssertEqual(transcript.summaryHead, "They discussed sentences.")
        XCTAssertEqual(transcript.tail.count, originalTailCount - batch.count)
        // Full history is preserved for retrieval regardless of compaction.
        XCTAssertEqual(transcript.allUtterances.count, 30)
    }

    func testKoreanTextEstimatesHigherPerCharacter() {
        let korean = TokenEstimator.estimate("오늘 회의에서 예산 이야기를 했어요")
        let english = TokenEstimator.estimate("today we talked about budget stuff")
        // Same-ish length strings: Korean should estimate more tokens per char.
        XCTAssertGreaterThan(korean, english / 2)
    }
}
