// ⚠️ UNVERIFIED-ON-DEVICE + API-SHAPE-UNVERIFIED: SpeechAnalyzer/SpeechTranscriber
// are iOS 26 APIs (WWDC25 session 277). This wrapper's *shape* is right but exact
// signatures MUST be reconciled against the SDK in Xcode — expect compile fixes.
// Fallback pre-iOS-26 path (SFSpeechRecognizer / WhisperKit) is a TODO(M1).
import Foundation
import AVFoundation
import Speech
import SaturdayCore

/// Streams finalized utterances from the mic via on-device ASR.
final class SpeechTranscriberEngine {
    func stream(audio: AudioSessionController) -> AsyncThrowingStream<Utterance, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    guard #available(iOS 26.0, *) else {
                        throw TranscriberError.osTooOld
                    }
                    let transcriber = SpeechTranscriber(locale: .current,
                                                        transcriptionOptions: [],
                                                        reportingOptions: [.volatileResults],
                                                        attributeOptions: [.audioTimeRange])
                    let analyzer = SpeechAnalyzer(modules: [transcriber])

                    let (inputSequence, inputBuilder) = AsyncStream<AnalyzerInput>.makeStream()
                    let format = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber])

                    audio.engine.inputNode.installTap(onBus: 0, bufferSize: 4096,
                                                      format: audio.engine.inputNode.outputFormat(forBus: 0)) { buffer, _ in
                        // TODO(M0-SpikeB): convert buffer to `format` before yielding.
                        inputBuilder.yield(AnalyzerInput(buffer: buffer))
                    }

                    try await analyzer.start(inputSequence: inputSequence)

                    let start = Date()
                    for try await result in transcriber.results where result.isFinal {
                        let text = String(result.text.characters)
                        let now = Date().timeIntervalSince(start)
                        continuation.yield(Utterance(start: now, end: now, text: text))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    enum TranscriberError: Error {
        case osTooOld // TODO(M1): SFSpeechRecognizer/WhisperKit fallback
    }
}
