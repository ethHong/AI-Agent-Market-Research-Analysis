// ⚠️ UNVERIFIED-ON-DEVICE: authored off-Mac; compiles only in Xcode (iOS 26 SDK).
// See app/README.md for project generation and HANDOFF.md for verification status.
import SwiftUI

@main
struct SaturdayApp: App {
    @State private var session = SessionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(session)
        }
    }
}
