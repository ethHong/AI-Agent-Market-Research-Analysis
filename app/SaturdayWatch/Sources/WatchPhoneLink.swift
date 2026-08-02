// ⚠️ UNVERIFIED-ON-DEVICE: authored off-Mac; needs paired-device testing (M2).
import Foundation
import Observation
import WatchConnectivity

@Observable
final class WatchPhoneLink: NSObject, WCSessionDelegate {
    private(set) var lastAnswer: String?
    private(set) var isPhoneReachable = false
    private(set) var isBusy = false
    var lastError: String?

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func startSession() {
        sendCommand("start")
    }

    func endSession() {
        sendCommand("stop")
    }

    func ask(_ question: String) {
        guard WCSession.default.isReachable else {
            lastError = "iPhone not reachable"
            return
        }
        isBusy = true
        WCSession.default.sendMessage(["query": question], replyHandler: { [weak self] reply in
            Task { @MainActor in
                self?.isBusy = false
                self?.lastAnswer = reply["answer"] as? String ?? "No answer"
            }
        }, errorHandler: { [weak self] error in
            Task { @MainActor in
                self?.isBusy = false
                self?.lastError = error.localizedDescription
            }
        })
    }

    private func sendCommand(_ command: String) {
        guard WCSession.default.isReachable else {
            lastError = "iPhone not reachable — open Saturday on your phone"
            return
        }
        WCSession.default.sendMessage(["command": command], replyHandler: nil) { [weak self] error in
            Task { @MainActor in self?.lastError = error.localizedDescription }
        }
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        Task { @MainActor in self.isPhoneReachable = session.isReachable }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in self.isPhoneReachable = session.isReachable }
    }
}
