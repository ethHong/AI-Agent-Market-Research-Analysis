// ⚠️ UNVERIFIED-ON-DEVICE: authored off-Mac; needs paired-device testing (M2).
// Phone side of the watch link. Watch primary input is dictated TEXT (robust);
// chunked audio is the M0 Spike C experiment (doc 01 §3).
import Foundation
import WatchConnectivity

final class PhoneConnectivity: NSObject, WCSessionDelegate {
    var onWatchQuery: ((String) async -> String)?
    var onWatchSessionCommand: ((String) -> Void)?

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }

    /// Watch → phone messages:
    ///   {"command": "start"|"stop"}           session control
    ///   {"query": "<dictated question>"}      Q&A (reply expected)
    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void) {
        if let command = message["command"] as? String {
            onWatchSessionCommand?(command)
            replyHandler(["ok": true])
            return
        }
        guard let query = message["query"] as? String, let onWatchQuery else {
            replyHandler(["error": "unsupported message"])
            return
        }
        Task {
            let answer = await onWatchQuery(query)
            replyHandler(["answer": answer])
        }
    }

    /// M0 Spike C experimental path: compressed audio chunks from the watch.
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        // TODO(M0-SpikeC): reassemble AAC chunks → feed phone-side ASR pipeline;
        // measure end-to-end lag before committing to this path.
    }
}
