import Foundation

/// In-session wake-phrase detection on the live ASR transcript (doc 02 §3 —
/// the zero-extra-model path; a Core ML KWS model can replace this behind the
/// same surface if transcript latency disappoints).
///
/// Feed it finalized transcript text as it streams in; it reports a detection
/// once per cooldown window and extracts the query text following the phrase.
public struct HotphraseDetector: Sendable {
    public struct Detection: Equatable, Sendable {
        /// Text after the phrase in the same chunk — often the start of the
        /// user's question ("Saturday, what did she say" → "what did she say").
        public let trailingQuery: String
        public let atSessionTime: TimeInterval
    }

    public struct Config: Sendable {
        public var phrases: [String]
        /// Seconds during which repeat detections are ignored.
        public var cooldown: TimeInterval

        public init(phrases: [String] = ["hey saturday", "saturday,"], cooldown: TimeInterval = 5) {
            self.phrases = phrases
            self.cooldown = cooldown
        }
    }

    private let config: Config
    private let normalizedPhrases: [[String]]
    private var lastDetectionTime: TimeInterval = -.infinity

    public init(config: Config = Config()) {
        self.config = config
        self.normalizedPhrases = config.phrases.map(Self.normalize)
    }

    /// Scans one finalized transcript chunk. `sessionTime` is the chunk's
    /// position in the session (used for the cooldown).
    public mutating func scan(_ text: String, sessionTime: TimeInterval) -> Detection? {
        guard sessionTime - lastDetectionTime >= config.cooldown else { return nil }
        let words = Self.normalize(text)
        guard !words.isEmpty else { return nil }

        for phrase in normalizedPhrases where !phrase.isEmpty {
            guard words.count >= phrase.count else { continue }
            for start in 0...(words.count - phrase.count) {
                if Array(words[start..<(start + phrase.count)]) == phrase {
                    lastDetectionTime = sessionTime
                    let trailing = words[(start + phrase.count)...].joined(separator: " ")
                    return Detection(trailingQuery: trailing, atSessionTime: sessionTime)
                }
            }
        }
        return nil
    }

    /// Lowercase word list with punctuation stripped — "Saturday, what's up?" →
    /// ["saturday", "whats", "up"]. Phrases are normalized the same way, so a
    /// configured "saturday," matches spoken "Saturday" regardless of ASR
    /// punctuation choices.
    static func normalize(_ text: String) -> [String] {
        text.lowercased()
            .split(whereSeparator: { $0.isWhitespace })
            .map { word in String(word.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }) }
            .filter { !$0.isEmpty }
    }
}
