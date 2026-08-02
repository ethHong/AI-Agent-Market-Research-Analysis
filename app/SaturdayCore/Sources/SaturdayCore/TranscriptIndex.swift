import Foundation

/// Retrieval over the whole session transcript (doc 06 §8) — recall/catch-up/
/// synthesize queries reference content far older than the verbatim tail.
public protocol TranscriptSearching: Sendable {
    mutating func add(_ utterance: Utterance)
    func search(_ query: String, limit: Int) -> [ScoredUtterance]
}

public struct ScoredUtterance: Equatable, Sendable {
    public let utterance: Utterance
    public let score: Double
}

/// Pure-Swift BM25 index. v1 on-device can swap in SQLite FTS5 behind the same
/// protocol; this implementation is dependency-free so it tests everywhere and
/// is honestly fast enough for single-session scale (hours of speech ≈ a few
/// thousand utterances).
public struct BM25TranscriptIndex: TranscriptSearching, Sendable {
    private struct Doc: Sendable {
        let utterance: Utterance
        let terms: [String: Int]
        let length: Int
    }

    private var docs: [Doc] = []
    private var termDocFrequency: [String: Int] = [:]
    private var totalLength = 0

    private let k1: Double
    private let b: Double

    public init(k1: Double = 1.4, b: Double = 0.75) {
        self.k1 = k1
        self.b = b
    }

    public mutating func add(_ utterance: Utterance) {
        let tokens = Self.tokenize(utterance.text)
        guard !tokens.isEmpty else { return }
        var counts: [String: Int] = [:]
        for token in tokens { counts[token, default: 0] += 1 }
        docs.append(Doc(utterance: utterance, terms: counts, length: tokens.count))
        for term in counts.keys { termDocFrequency[term, default: 0] += 1 }
        totalLength += tokens.count
    }

    public func search(_ query: String, limit: Int = 5) -> [ScoredUtterance] {
        guard !docs.isEmpty else { return [] }
        let queryTerms = Self.tokenize(query)
        guard !queryTerms.isEmpty else { return [] }
        let avgLength = Double(totalLength) / Double(docs.count)
        let n = Double(docs.count)

        var results: [ScoredUtterance] = []
        for doc in docs {
            var score = 0.0
            for term in Set(queryTerms) {
                guard let tf = doc.terms[term], let df = termDocFrequency[term] else { continue }
                let idf = log(1 + (n - Double(df) + 0.5) / (Double(df) + 0.5))
                let tfNorm = Double(tf) * (k1 + 1)
                    / (Double(tf) + k1 * (1 - b + b * Double(doc.length) / avgLength))
                score += idf * tfNorm
            }
            if score > 0 {
                results.append(ScoredUtterance(utterance: doc.utterance, score: score))
            }
        }
        return Array(results.sorted { $0.score > $1.score }.prefix(limit))
    }

    /// Lowercased word tokens; CJK/Hangul runs are additionally split into
    /// character bigrams so Korean works without a morphological analyzer.
    static func tokenize(_ text: String) -> [String] {
        var tokens: [String] = []
        var currentWord = ""
        var currentCJK = ""

        func flushWord() {
            if !currentWord.isEmpty { tokens.append(currentWord); currentWord = "" }
        }
        func flushCJK() {
            guard !currentCJK.isEmpty else { return }
            let chars = Array(currentCJK)
            if chars.count == 1 {
                tokens.append(String(chars[0]))
            } else {
                for i in 0..<(chars.count - 1) {
                    tokens.append(String(chars[i]) + String(chars[i + 1]))
                }
            }
            currentCJK = ""
        }

        for character in text.lowercased() {
            let isCJK = character.unicodeScalars.contains { scalar in
                (0xAC00...0xD7AF).contains(scalar.value) ||
                (0x1100...0x11FF).contains(scalar.value) ||
                (0x3040...0x30FF).contains(scalar.value) ||
                (0x4E00...0x9FFF).contains(scalar.value)
            }
            if isCJK {
                flushWord()
                currentCJK.append(character)
            } else if character.isLetter || character.isNumber {
                flushCJK()
                currentWord.append(character)
            } else {
                flushWord()
                flushCJK()
            }
        }
        flushWord()
        flushCJK()
        return tokens
    }
}
