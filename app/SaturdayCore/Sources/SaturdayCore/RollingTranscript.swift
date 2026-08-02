import Foundation

/// Two-tier rolling transcript (doc 04 §4): a verbatim tail bounded by a token
/// budget, plus an LLM-maintained compact summary of everything older.
///
/// The type owns *when* compaction is needed and *which* utterances to fold in;
/// the actual summarization is the LLM's job (see `Summarizer`), so this stays
/// pure and testable.
public struct RollingTranscript: Sendable {
    public struct Config: Sendable {
        /// Token budget for the verbatim tail (what can go into a prompt verbatim).
        public var tailTokenBudget: Int
        /// Compaction triggers when the tail exceeds budget by this factor,
        /// so we batch compactions instead of summarizing on every utterance.
        public var compactionSlack: Double

        public init(tailTokenBudget: Int = 1200, compactionSlack: Double = 1.5) {
            self.tailTokenBudget = tailTokenBudget
            self.compactionSlack = compactionSlack
        }
    }

    public private(set) var summaryHead: String = ""
    public private(set) var tail: [Utterance] = []
    /// Full session history (kept for retrieval/indexing and post-session Q&A;
    /// persistence is the app layer's job).
    public private(set) var allUtterances: [Utterance] = []

    public let config: Config

    public init(config: Config = Config()) {
        self.config = config
    }

    public mutating func append(_ utterance: Utterance) {
        allUtterances.append(utterance)
        tail.append(utterance)
    }

    public var tailTokens: Int { TokenEstimator.estimate(tail) }

    /// Utterances that should be folded into the summary, or empty if no
    /// compaction is due. Keeps at least the newest utterances that fit the
    /// tail budget; everything older is compaction input.
    public func compactionBatch() -> [Utterance] {
        let threshold = Int(Double(config.tailTokenBudget) * config.compactionSlack)
        guard tailTokens > threshold else { return [] }

        var keptTokens = 0
        var keepFromIndex = tail.count
        for (index, utterance) in tail.enumerated().reversed() {
            let tokens = TokenEstimator.estimate(utterance.text)
            if keptTokens + tokens > config.tailTokenBudget { break }
            keptTokens += tokens
            keepFromIndex = index
        }
        return Array(tail[..<keepFromIndex])
    }

    /// Applies the summarizer's output: drops the compacted utterances from the
    /// tail and replaces the summary head (the summarizer received the previous
    /// summary as input, so its output is the *whole* new head).
    public mutating func applyCompaction(newSummaryHead: String, compactedCount: Int) {
        precondition(compactedCount <= tail.count)
        tail.removeFirst(compactedCount)
        summaryHead = newSummaryHead
    }
}

/// LLM-backed summarizer contract. The app layer implements this with
/// FoundationModels/MLX; tests use a stub.
public protocol Summarizer: Sendable {
    /// Returns the new full summary head, given the previous head and the
    /// utterances being folded in.
    func compact(previousSummary: String, adding utterances: [Utterance]) async throws -> String
}
