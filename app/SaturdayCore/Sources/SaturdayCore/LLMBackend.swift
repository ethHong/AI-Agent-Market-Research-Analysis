import Foundation

/// Backend-neutral LLM contract (doc 04 §6). The app layer provides:
///   - AFMBackend  — Apple FoundationModels (primary)
///   - MLXBackend  — MLX Swift open model (fallback/quality tier)
/// Mirrors the shape of iOS 27's upcoming `LanguageModel` provider protocol so
/// migration is mechanical.
public protocol LLMBackend: Sendable {
    var identifier: String { get }
    /// Whether this backend can run on the current device right now.
    func availability() async -> LLMAvailability
    /// Plain generation. Implementations own their stop conditions; callers own
    /// prompt budgeting (`PromptAssembler`).
    func generate(prompt: String, maxTokens: Int) async throws -> String
}

public enum LLMAvailability: Equatable, Sendable {
    case available
    case unavailable(reason: String)
}

public enum LLMError: Error, Equatable, Sendable {
    case contextWindowExceeded
    case guardrailRefusal
    case backendUnavailable
    case generationFailed(String)
}

/// Routes to the first available backend in priority order (AFM → MLX).
public struct LLMRouter: Sendable {
    public let backends: [any LLMBackend]

    public init(backends: [any LLMBackend]) {
        self.backends = backends
    }

    public func resolve() async -> (any LLMBackend)? {
        for backend in backends {
            if await backend.availability() == .available { return backend }
        }
        return nil
    }
}
