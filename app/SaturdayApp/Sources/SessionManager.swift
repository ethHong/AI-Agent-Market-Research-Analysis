// ⚠️ UNVERIFIED-ON-DEVICE: authored off-Mac; needs Xcode compile + device test.
import Foundation
import Observation
import SaturdayCore

/// Owns one listening session end-to-end: audio → ASR → rolling transcript →
/// (on query) retrieval → prompt → LLM → answer. UI observes this.
@Observable
@MainActor
final class SessionManager {
    // MARK: observable state
    private(set) var machineState: SessionStateMachine.State = .idle
    private(set) var liveTranscriptTail: [Utterance] = []
    private(set) var currentAnswer: Answer?
    private(set) var capturedItems: [CapturedItem] = []
    var lastError: String?

    struct Answer: Identifiable {
        let id = UUID()
        let text: String
        let source: AnswerSource
        /// Timestamp for tap-to-verify when the answer is transcript-grounded.
        let sourceTime: TimeInterval?
    }

    // MARK: components
    private var machine = SessionStateMachine()
    private var transcript = RollingTranscript()
    private var index = BM25TranscriptIndex()
    private var hotphrase = HotphraseDetector(config: .init(phrases: ["hey saturday"], cooldown: 5))
    /// Wake phrase is an off-by-default beta (doc 06 decision 1).
    var wakePhraseEnabled = false

    private let audio = AudioSessionController()
    private let transcriber = SpeechTranscriberEngine()
    private let orchestrator: QueryOrchestrator
    private var sessionStartDate: Date?
    private var transcriptionTask: Task<Void, Never>?

    init() {
        let backends: [any LLMBackend] = [AFMBackend(), MLXBackend()]
        orchestrator = QueryOrchestrator(router: LLMRouter(backends: backends))
        audio.onInterruptionBegan = { [weak self] in
            Task { @MainActor in self?.handleInterruption() }
        }
    }

    // MARK: session lifecycle

    func startSession(tag: SessionTag = .meeting, focus: String? = nil) async {
        guard machine.handle(.startSession) else { return }
        machineState = machine.state
        transcript = RollingTranscript()
        index = BM25TranscriptIndex()
        capturedItems = []
        sessionStartDate = Date()
        orchestrator.configure(tag: tag, focus: focus)

        do {
            try await audio.activate()
            transcriptionTask = Task { [weak self] in
                guard let self else { return }
                do {
                    for try await utterance in self.transcriber.stream(audio: self.audio) {
                        await self.ingest(utterance)
                    }
                } catch {
                    await MainActor.run { self.lastError = "Transcription stopped: \(error.localizedDescription)" }
                }
            }
        } catch {
            lastError = "Couldn't start listening: \(error.localizedDescription)"
            machine.handle(.endSession)
            machineState = machine.state
        }
    }

    func endSession() async {
        transcriptionTask?.cancel()
        await audio.deactivate()
        machine.handle(.endSession)
        machineState = machine.state
        // TODO(M3): end-of-session summary card + commitment detection pass.
    }

    /// User tapped "resume" (from the local notification or in-app banner).
    func resumeAfterInterruption() async {
        guard machine.state == .interrupted else { return }
        do {
            try await audio.activate()
            machine.handle(.userResumed)
            machineState = machine.state
        } catch {
            lastError = "Couldn't resume: \(error.localizedDescription)"
        }
    }

    // MARK: query path (push-to-talk / watch / wake phrase all land here)

    func ask(_ question: String) async {
        guard machine.handle(.queryCaptured) else { return }
        machineState = machine.state
        defer {
            machine.handle(.answerDelivered)
            machineState = machine.state
        }
        do {
            let result = try await orchestrator.answer(
                question: question,
                transcript: transcript,
                index: index
            )
            currentAnswer = Answer(text: result.text, source: result.source, sourceTime: result.sourceTime)
        } catch {
            lastError = "Answer failed: \(error.localizedDescription)"
        }
    }

    // MARK: internals

    private func ingest(_ utterance: Utterance) async {
        transcript.append(utterance)
        index.add(utterance)
        liveTranscriptTail = transcript.tail.suffix(8)

        if wakePhraseEnabled,
           let detection = hotphrase.scan(utterance.text, sessionTime: utterance.start),
           !detection.trailingQuery.isEmpty {
            await ask(detection.trailingQuery)
        }

        let batch = transcript.compactionBatch()
        if !batch.isEmpty {
            do {
                let newHead = try await orchestrator.compact(
                    previousSummary: transcript.summaryHead, adding: batch)
                transcript.applyCompaction(newSummaryHead: newHead, compactedCount: batch.count)
            } catch {
                // Compaction failure is non-fatal; retry on next batch. The prompt
                // assembler will trim harder in the meantime.
            }
        }
    }

    private func handleInterruption() {
        machine.handle(.interruptionBegan)
        machineState = machine.state
        audio.postResumeNotification()
    }
}
