import Foundation

/// A single transcribed utterance in a session.
public struct Utterance: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    /// Seconds from session start.
    public let start: TimeInterval
    public let end: TimeInterval
    public let text: String
    /// ASR speaker-change hint if available ("S1", "S2", …). Nil until diarization ships.
    public let speakerHint: String?

    public init(id: UUID = UUID(), start: TimeInterval, end: TimeInterval,
                text: String, speakerHint: String? = nil) {
        self.id = id
        self.start = start
        self.end = end
        self.text = text
        self.speakerHint = speakerHint
    }
}

/// Session context tag — tunes summary templates and answer tone.
public enum SessionTag: String, Codable, CaseIterable, Sendable {
    case meeting, lecture, interview, casual
}

/// Where an answer's content came from. Drives the trust-UX source labels
/// (doc 06 §6): 🗣 conversation / 🧠 general knowledge / 🌐 web.
public enum AnswerSource: String, Codable, Sendable {
    case conversation
    case generalKnowledge
    case web
    case mixed
}

/// An item captured during a session ("note that", detected commitment, action item).
public struct CapturedItem: Identifiable, Equatable, Codable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case note, actionItem, commitment, decision
    }
    public let id: UUID
    public let kind: Kind
    public let text: String
    /// Timestamp in the session the item refers to (for tap-to-verify).
    public let sourceTime: TimeInterval?

    public init(id: UUID = UUID(), kind: Kind, text: String, sourceTime: TimeInterval? = nil) {
        self.id = id
        self.kind = kind
        self.text = text
        self.sourceTime = sourceTime
    }
}
