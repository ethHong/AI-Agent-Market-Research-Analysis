import Foundation

/// Assembles a QA prompt within the Foundation Models 4,096-token window
/// (input + output combined — TN3193). Content is added in priority order and
/// lower-priority sections are dropped/trimmed to fit:
///
///   1. system instructions + question  (never dropped)
///   2. session focus                   (never dropped; it's tiny)
///   3. verbatim tail                   (trimmed oldest-first)
///   4. retrieved spans (RAG)           (dropped low-score-first)
///   5. summary head                    (dropped first)
public struct PromptAssembler: Sendable {
    public struct Budget: Sendable {
        /// Total window (input + output).
        public var contextWindow: Int
        /// Tokens reserved for the model's answer.
        public var reservedForOutput: Int
        /// Multiplier applied to estimates to absorb tokenizer error (biased safe).
        public var safetyFactor: Double

        public var inputBudget: Int {
            Int(Double(contextWindow - reservedForOutput) / safetyFactor)
        }

        public init(contextWindow: Int = 4096, reservedForOutput: Int = 600, safetyFactor: Double = 1.15) {
            self.contextWindow = contextWindow
            self.reservedForOutput = reservedForOutput
            self.safetyFactor = safetyFactor
        }
    }

    public struct Input: Sendable {
        public var systemPrompt: String
        public var focus: String?
        public var summaryHead: String
        /// Retrieval results, highest score first.
        public var retrievedSpans: [String]
        public var tail: [Utterance]
        public var question: String

        public init(systemPrompt: String, focus: String? = nil, summaryHead: String = "",
                    retrievedSpans: [String] = [], tail: [Utterance] = [], question: String) {
            self.systemPrompt = systemPrompt
            self.focus = focus
            self.summaryHead = summaryHead
            self.retrievedSpans = retrievedSpans
            self.tail = tail
            self.question = question
        }
    }

    public struct Output: Equatable, Sendable {
        public var prompt: String
        public var estimatedTokens: Int
        public var droppedSummary: Bool
        public var droppedSpanCount: Int
        public var trimmedTailCount: Int
    }

    public let budget: Budget

    public init(budget: Budget = Budget()) {
        self.budget = budget
    }

    public func assemble(_ input: Input) -> Output {
        let fixed = renderFixed(input)
        let fixedTokens = TokenEstimator.estimate(fixed.joined(separator: "\n"))
        var remaining = budget.inputBudget - fixedTokens

        // 3. Verbatim tail, newest kept first.
        var keptTail: [Utterance] = []
        var trimmedTail = 0
        for utterance in input.tail.reversed() {
            let tokens = TokenEstimator.estimate(utterance.text) + 4 // timestamp overhead
            if tokens <= remaining {
                keptTail.insert(utterance, at: 0)
                remaining -= tokens
            } else {
                trimmedTail += 1
            }
        }

        // 4. Retrieved spans, best-scored first.
        var keptSpans: [String] = []
        var droppedSpans = 0
        for span in input.retrievedSpans {
            let tokens = TokenEstimator.estimate(span) + 2
            if tokens <= remaining {
                keptSpans.append(span)
                remaining -= tokens
            } else {
                droppedSpans += 1
            }
        }

        // 5. Summary head last.
        var summary = input.summaryHead
        var droppedSummary = false
        if !summary.isEmpty {
            let tokens = TokenEstimator.estimate(summary) + 2
            if tokens > remaining {
                summary = ""
                droppedSummary = true
            } else {
                remaining -= tokens
            }
        }

        var sections: [String] = [input.systemPrompt]
        if let focus = input.focus, !focus.isEmpty {
            sections.append("Session focus: \(focus)")
        }
        if !summary.isEmpty {
            sections.append("Earlier in this conversation (summary):\n\(summary)")
        }
        if !keptSpans.isEmpty {
            sections.append("Possibly relevant earlier moments:\n" + keptSpans.map { "- \($0)" }.joined(separator: "\n"))
        }
        if !keptTail.isEmpty {
            let lines = keptTail.map { "[\(Self.timestamp($0.start))] \($0.speakerHint.map { "\($0): " } ?? "")\($0.text)" }
            sections.append("Most recent conversation:\n" + lines.joined(separator: "\n"))
        }
        sections.append("Question: \(input.question)")

        let prompt = sections.joined(separator: "\n\n")
        return Output(prompt: prompt,
                      estimatedTokens: TokenEstimator.estimate(prompt),
                      droppedSummary: droppedSummary,
                      droppedSpanCount: droppedSpans,
                      trimmedTailCount: trimmedTail)
    }

    private func renderFixed(_ input: Input) -> [String] {
        var parts = [input.systemPrompt, "Question: \(input.question)"]
        if let focus = input.focus, !focus.isEmpty {
            parts.append("Session focus: \(focus)")
        }
        return parts
    }

    static func timestamp(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
