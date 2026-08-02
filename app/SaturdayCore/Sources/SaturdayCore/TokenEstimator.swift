import Foundation

/// Cheap token-count estimate used for context budgeting.
///
/// Foundation Models exposes no public tokenizer, so budgeting works on estimates
/// with a safety margin (`PromptAssembler.Budget.safetyFactor`). Heuristic:
/// ~4 chars/token for Latin text, ~1.4 chars/token for CJK/Hangul — biased high
/// (overestimating token use is safe; underestimating overflows the 4k window).
public enum TokenEstimator {
    public static func estimate(_ text: String) -> Int {
        guard !text.isEmpty else { return 0 }
        var latinish = 0
        var cjk = 0
        for scalar in text.unicodeScalars {
            switch scalar.value {
            case 0xAC00...0xD7AF,   // Hangul syllables
                 0x1100...0x11FF,   // Hangul jamo
                 0x3040...0x30FF,   // Kana
                 0x4E00...0x9FFF:   // CJK ideographs
                cjk += 1
            default:
                latinish += 1
            }
        }
        let estimate = Double(latinish) / 4.0 + Double(cjk) / 1.4
        return max(1, Int(estimate.rounded(.up)))
    }

    public static func estimate(_ utterances: [Utterance]) -> Int {
        utterances.reduce(0) { $0 + estimate($1.text) }
    }
}
