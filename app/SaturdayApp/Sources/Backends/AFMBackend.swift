// ⚠️ UNVERIFIED-ON-DEVICE + API-SHAPE-UNVERIFIED: FoundationModels is the iOS 26
// framework (WWDC25 286/301). Reconcile signatures in Xcode; test guardrail
// refusals and .exceededContextWindowSize on a real Apple Intelligence device.
import Foundation
import SaturdayCore
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Apple Foundation Models backend — Tier 1 (doc 01 §5).
struct AFMBackend: LLMBackend {
    let identifier = "apple-foundation-models"

    func availability() async -> LLMAvailability {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return .available
            case .unavailable(let reason):
                return .unavailable(reason: String(describing: reason))
            }
        }
        return .unavailable(reason: "iOS 26 required")
        #else
        return .unavailable(reason: "FoundationModels framework absent")
        #endif
    }

    func generate(prompt: String, maxTokens: Int) async throws -> String {
        #if canImport(FoundationModels)
        guard #available(iOS 26.0, *) else { throw LLMError.backendUnavailable }
        do {
            // A fresh session per request: rolling context is OUR job (PromptAssembler),
            // not the framework's transcript accumulation — this sidesteps unbounded
            // session growth against the fixed 4,096-token window (TN3193).
            let session = LanguageModelSession()
            let response = try await session.respond(
                to: prompt,
                options: GenerationOptions(maximumResponseTokens: maxTokens)
            )
            return response.content
        } catch let error as LanguageModelSession.GenerationError {
            switch error {
            case .exceededContextWindowSize:
                throw LLMError.contextWindowExceeded
            case .guardrailViolation:
                throw LLMError.guardrailRefusal
            default:
                throw LLMError.generationFailed(String(describing: error))
            }
        }
        #else
        throw LLMError.backendUnavailable
        #endif
    }
}
