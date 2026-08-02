// ⚠️ UNVERIFIED-ON-DEVICE: authored off-Mac; needs Xcode compile + device test.
// One intent backs every activation surface (doc 02 §4): Action Button,
// Control Center / Lock Screen control, widgets, and "Hey Siri, start Saturday".
import AppIntents

struct StartListeningIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Listening Session"
    static let description = IntentDescription("Starts a Saturday listening session.")
    // Recording must start in the foreground — this is the iOS rule, not a choice.
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        // The app observes this via NotificationCenter and calls
        // SessionManager.startSession(); keeps the intent free of app state.
        NotificationCenter.default.post(name: .saturdayStartSession, object: nil)
        return .result()
    }
}

struct StopListeningIntent: AppIntent {
    static let title: LocalizedStringResource = "End Listening Session"
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .saturdayEndSession, object: nil)
        return .result()
    }
}

struct SaturdayShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartListeningIntent(),
            phrases: [
                "Start \(.applicationName)",
                "\(.applicationName), start listening"
            ],
            shortTitle: "Start Session",
            systemImageName: "waveform"
        )
        AppShortcut(
            intent: StopListeningIntent(),
            phrases: ["Stop \(.applicationName)"],
            shortTitle: "End Session",
            systemImageName: "stop.circle"
        )
    }
}

extension Notification.Name {
    static let saturdayStartSession = Notification.Name("saturday.start")
    static let saturdayEndSession = Notification.Name("saturday.end")
}
