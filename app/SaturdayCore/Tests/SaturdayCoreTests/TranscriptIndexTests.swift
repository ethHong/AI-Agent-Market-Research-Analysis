import XCTest
@testable import SaturdayCore

final class TranscriptIndexTests: XCTestCase {
    private func makeIndex() -> BM25TranscriptIndex {
        var index = BM25TranscriptIndex()
        let lines: [(TimeInterval, String)] = [
            (10, "Good morning everyone, thanks for joining."),
            (60, "The Q3 revenue target is twelve million dollars."),
            (120, "Marketing wants to launch the campaign in October."),
            (180, "Jin will own the vendor contract renewal."),
            (240, "Let's circle back on the budget next week."),
            (300, "The deadline for the deck is Friday afternoon.")
        ]
        for (time, text) in lines {
            index.add(Utterance(start: time, end: time + 5, text: text))
        }
        return index
    }

    func testRelevantUtteranceRanksFirst() {
        let index = makeIndex()
        let results = index.search("what was the revenue target", limit: 3)
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results[0].utterance.text.contains("twelve million"))
    }

    func testDeadlineQuery() {
        let index = makeIndex()
        let results = index.search("deadline for the deck", limit: 2)
        XCTAssertTrue(results[0].utterance.text.contains("Friday"))
    }

    func testNoMatchReturnsEmpty() {
        let index = makeIndex()
        XCTAssertTrue(index.search("quantum chromodynamics", limit: 3).isEmpty)
    }

    func testEmptyQueryReturnsEmpty() {
        let index = makeIndex()
        XCTAssertTrue(index.search("   ", limit: 3).isEmpty)
    }

    func testLimitRespected() {
        let index = makeIndex()
        XCTAssertLessThanOrEqual(index.search("the", limit: 2).count, 2)
    }

    func testKoreanBigramSearch() {
        var index = BM25TranscriptIndex()
        index.add(Utterance(start: 10, end: 15, text: "예산은 천이백만 달러로 확정됐습니다"))
        index.add(Utterance(start: 20, end: 25, text: "마케팅 캠페인은 시월에 시작합니다"))
        let results = index.search("예산 얼마였지", limit: 2)
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results[0].utterance.text.contains("천이백만"))
    }

    func testTokenizerSplitsCJKBigrams() {
        let tokens = BM25TranscriptIndex.tokenize("예산 budget")
        XCTAssertTrue(tokens.contains("예산"))
        XCTAssertTrue(tokens.contains("budget"))
    }
}
