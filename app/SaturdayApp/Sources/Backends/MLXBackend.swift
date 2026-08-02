// TODO(M4): MLX Swift open-model backend — Tier 2 (doc 01 §5).
// Plan: add mlx-swift-examples' MLXLLM as an SPM dependency IN XCODE ONLY (it
// cannot build on Linux, so it must not be added to SaturdayCore/Package.swift).
// Model: Qwen3-4B-Instruct 4-bit (8 GB devices) / Qwen3-1.7B (6 GB devices),
// downloaded via Background Assets — never bundled. Respect the ~4 GB jetsam
// ceiling; tool calls via constrained JSON + SaturdayCore.ToolCallParser.
import Foundation
import SaturdayCore

struct MLXBackend: LLMBackend {
    let identifier = "mlx-qwen3"

    func availability() async -> LLMAvailability {
        .unavailable(reason: "MLX backend not implemented yet (M4)")
    }

    func generate(prompt: String, maxTokens: Int) async throws -> String {
        throw LLMError.backendUnavailable
    }
}
