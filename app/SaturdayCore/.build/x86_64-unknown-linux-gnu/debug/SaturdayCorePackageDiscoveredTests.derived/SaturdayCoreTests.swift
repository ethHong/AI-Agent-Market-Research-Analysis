import XCTest
@testable import SaturdayCoreTests

fileprivate extension DDGParserTests {
    @available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
    static nonisolated(unsafe) let __allTests__DDGParserTests = [
        ("testGarbageInputReturnsEmpty", testGarbageInputReturnsEmpty),
        ("testLimitRespected", testLimitRespected),
        ("testParsesHTMLEndpoint", testParsesHTMLEndpoint),
        ("testParsesLiteEndpoint", testParsesLiteEndpoint),
        ("testRedirectURLResolution", testRedirectURLResolution),
        ("testTagStrippingAndUnescaping", testTagStrippingAndUnescaping)
    ]
}

fileprivate extension HotphraseDetectorTests {
    @available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
    static nonisolated(unsafe) let __allTests__HotphraseDetectorTests = [
        ("testBareSaturdayAsDateDoesNotTrigger", testBareSaturdayAsDateDoesNotTrigger),
        ("testCooldownSuppressesRepeats", testCooldownSuppressesRepeats),
        ("testDetectsPhraseAndExtractsQuery", testDetectsPhraseAndExtractsQuery),
        ("testDetectsWithASRPunctuation", testDetectsWithASRPunctuation),
        ("testNoPhraseNoDetection", testNoPhraseNoDetection)
    ]
}

fileprivate extension PromptAssemblerTests {
    @available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
    static nonisolated(unsafe) let __allTests__PromptAssemblerTests = [
        ("testBudgetIsRespectedUnderOverload", testBudgetIsRespectedUnderOverload),
        ("testDropOrderSummaryBeforeQuestion", testDropOrderSummaryBeforeQuestion),
        ("testEverythingFitsWhenSmall", testEverythingFitsWhenSmall),
        ("testTailTrimsOldestFirst", testTailTrimsOldestFirst),
        ("testTimestampRendering", testTimestampRendering)
    ]
}

fileprivate extension RollingTranscriptTests {
    @available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
    static nonisolated(unsafe) let __allTests__RollingTranscriptTests = [
        ("testApplyCompactionUpdatesTailAndSummary", testApplyCompactionUpdatesTailAndSummary),
        ("testCompactionTriggersAboveSlackThreshold", testCompactionTriggersAboveSlackThreshold),
        ("testKoreanTextEstimatesHigherPerCharacter", testKoreanTextEstimatesHigherPerCharacter),
        ("testNoCompactionUnderBudget", testNoCompactionUnderBudget)
    ]
}

fileprivate extension SessionStateMachineTests {
    @available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
    static nonisolated(unsafe) let __allTests__SessionStateMachineTests = [
        ("testEndFromInterrupted", testEndFromInterrupted),
        ("testHappyPath", testHappyPath),
        ("testInterruptionRequiresUserResume", testInterruptionRequiresUserResume),
        ("testInterruptionWhileAnswering", testInterruptionWhileAnswering),
        ("testInvalidTransitionsDoNotChangeState", testInvalidTransitionsDoNotChangeState),
        ("testRestartAfterEnd", testRestartAfterEnd)
    ]
}

fileprivate extension ToolCallingTests {
    @available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
    static nonisolated(unsafe) let __allTests__ToolCallingTests = [
        ("testMissingRequiredArgumentThrows", testMissingRequiredArgumentThrows),
        ("testNestedBracesInsideStringsSurvive", testNestedBracesInsideStringsSurvive),
        ("testNoJSONThrows", testNoJSONThrows),
        ("testNumberAndBoolArguments", testNumberAndBoolArguments),
        ("testParsesCleanJSON", testParsesCleanJSON),
        ("testParsesJSONSurroundedByProse", testParsesJSONSurroundedByProse),
        ("testUnknownToolThrows", testUnknownToolThrows)
    ]
}

fileprivate extension TranscriptIndexTests {
    @available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
    static nonisolated(unsafe) let __allTests__TranscriptIndexTests = [
        ("testDeadlineQuery", testDeadlineQuery),
        ("testEmptyQueryReturnsEmpty", testEmptyQueryReturnsEmpty),
        ("testKoreanBigramSearch", testKoreanBigramSearch),
        ("testLimitRespected", testLimitRespected),
        ("testNoMatchReturnsEmpty", testNoMatchReturnsEmpty),
        ("testRelevantUtteranceRanksFirst", testRelevantUtteranceRanksFirst),
        ("testTokenizerSplitsCJKBigrams", testTokenizerSplitsCJKBigrams)
    ]
}
@available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
func __SaturdayCoreTests__allTests() -> [XCTestCaseEntry] {
    return [
        testCase(DDGParserTests.__allTests__DDGParserTests),
        testCase(HotphraseDetectorTests.__allTests__HotphraseDetectorTests),
        testCase(PromptAssemblerTests.__allTests__PromptAssemblerTests),
        testCase(RollingTranscriptTests.__allTests__RollingTranscriptTests),
        testCase(SessionStateMachineTests.__allTests__SessionStateMachineTests),
        testCase(ToolCallingTests.__allTests__ToolCallingTests),
        testCase(TranscriptIndexTests.__allTests__TranscriptIndexTests)
    ]
}