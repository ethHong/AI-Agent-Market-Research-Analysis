// ⚠️ UNVERIFIED-ON-DEVICE: authored off-Mac; needs Xcode compile + device test.
import Foundation
import SaturdayCore

/// Glues SaturdayCore's pure logic to a live LLM backend: retrieval → prompt
/// assembly (4k budget) → generation → source labeling.
final class QueryOrchestrator: @unchecked Sendable {
    struct Result {
        let text: String
        let source: AnswerSource
        let sourceTime: TimeInterval?
    }

    private let router: LLMRouter
    private let assembler = PromptAssembler()
    private var tag: SessionTag = .meeting
    private var focus: String?

    init(router: LLMRouter) {
        self.router = router
    }

    func configure(tag: SessionTag, focus: String?) {
        self.tag = tag
        self.focus = focus
    }

    func answer(question: String,
                transcript: RollingTranscript,
                index: BM25TranscriptIndex) async throws -> Result {
        guard let backend = await router.resolve() else { throw LLMError.backendUnavailable }

        let hits = index.search(question, limit: 4)
        let spans = hits.map { "[\(PromptAssembler.timestamp($0.utterance.start))] \($0.utterance.text)" }

        let output = assembler.assemble(.init(
            systemPrompt: Self.systemPrompt(tag: tag),
            focus: focus,
            summaryHead: transcript.summaryHead,
            retrievedSpans: spans,
            tail: transcript.tail,
            question: question
        ))

        let text = try await backend.generate(prompt: output.prompt, maxTokens: 400)
        // Source heuristic v1: transcript-grounded if retrieval hit or the tail was
        // non-empty; the model is instructed to say when it fell back to general
        // knowledge. TODO(M1): parse an explicit source marker from the answer.
        let source: AnswerSource = hits.isEmpty && transcript.tail.isEmpty ? .generalKnowledge : .conversation
        return Result(text: text, source: source, sourceTime: hits.first?.utterance.start)
    }

    func compact(previousSummary: String, adding utterances: [Utterance]) async throws -> String {
        guard let backend = await router.resolve() else { throw LLMError.backendUnavailable }
        let lines = utterances.map { "[\(PromptAssembler.timestamp($0.start))] \($0.text)" }.joined(separator: "\n")
        let prompt = """
        You maintain running notes of a live conversation. Update the notes to \
        incorporate the new lines. Keep decisions, numbers, names, deadlines, and \
        commitments; drop filler. Maximum 200 words.

        Current notes:
        \(previousSummary.isEmpty ? "(none)" : previousSummary)

        New lines:
        \(lines)

        Updated notes:
        """
        return try await backend.generate(prompt: prompt, maxTokens: 300)
    }

    static func systemPrompt(tag: SessionTag) -> String {
        """
        You are Saturday, a discreet on-device assistant that has been listening to \
        the user's \(tag.rawValue) with their consent. Answer in at most 3 sentences, \
        grounded in the conversation excerpts provided. If the conversation does not \
        contain the answer, say so plainly and note you cannot check the web unless \
        the web tool is available. Never invent quotes.
        """
    }
}
