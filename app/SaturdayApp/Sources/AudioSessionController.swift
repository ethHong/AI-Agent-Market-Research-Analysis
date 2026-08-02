// ⚠️ UNVERIFIED-ON-DEVICE: authored off-Mac; needs Xcode compile + device test.
// Encodes the doc-02 constraints:
//   - recording must START in the foreground
//   - `audio` background mode keeps it alive after lock/app-switch
//   - after an interruption while backgrounded, reactivation FAILS → user must tap.
import AVFoundation
import UserNotifications

final class AudioSessionController {
    var onInterruptionBegan: (() -> Void)?

    let engine = AVAudioEngine()
    private var interruptionObserver: NSObjectProtocol?

    init() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            guard let info = notification.userInfo,
                  let typeRaw = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeRaw) else { return }
            if type == .began {
                self?.onInterruptionBegan?()
            }
            // .ended is intentionally NOT auto-resumed: setActive from background
            // throws (no entitlement). Resume is user-initiated only.
        }
    }

    /// Must be called while the app is in the foreground.
    func activate() async throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement,
                                options: [.duckOthers, .allowBluetooth])
        try session.setActive(true)
        if !engine.isRunning {
            engine.prepare()
            try engine.start()
        }
    }

    func deactivate() async {
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// "Tap to resume" local notification (doc 02 §2 — the only legal resume path
    /// when the interruption ended while we were backgrounded).
    func postResumeNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Saturday paused"
        content.body = "A call or Siri interrupted listening. Tap to resume your session."
        content.interruptionLevel = .timeSensitive
        let request = UNNotificationRequest(identifier: "saturday.resume",
                                            content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
