import Foundation

/// The session lifecycle (doc 04 §1).
///
/// Encodes the hard iOS constraint: after an audio interruption while backgrounded,
/// the mic CANNOT be reactivated programmatically — the only exit from `.interrupted`
/// is an explicit user resume (tap on the local notification / in app) or ending
/// the session.
public struct SessionStateMachine: Equatable, Sendable {
    public enum State: Equatable, Sendable {
        case idle
        case listening
        /// A question has been captured and is being answered.
        case answering
        /// Mic lost to a call/Siri; waiting for user tap-to-resume.
        case interrupted
        case ended
    }

    public enum Event: Equatable, Sendable {
        case startSession
        case queryCaptured        // wake phrase, push-to-talk, or watch query arrived
        case answerDelivered
        case interruptionBegan
        case userResumed          // user tapped "resume" (app foregrounded)
        case endSession
    }

    public private(set) var state: State = .idle

    public init() {}

    /// Applies an event. Returns `false` (state unchanged) for invalid transitions.
    @discardableResult
    public mutating func handle(_ event: Event) -> Bool {
        switch (state, event) {
        case (.idle, .startSession):
            state = .listening
        case (.listening, .queryCaptured):
            state = .answering
        case (.answering, .answerDelivered):
            state = .listening
        // Interruption can hit while listening or mid-answer.
        case (.listening, .interruptionBegan), (.answering, .interruptionBegan):
            state = .interrupted
        case (.interrupted, .userResumed):
            state = .listening
        case (.listening, .endSession), (.answering, .endSession), (.interrupted, .endSession):
            state = .ended
        case (.ended, .startSession):
            // Starting again from a finished session is a fresh session.
            state = .listening
        default:
            return false
        }
        return true
    }
}
