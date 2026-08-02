// ⚠️ UNVERIFIED-ON-DEVICE: authored off-Mac; needs paired-device testing (M2).
// Watch = trigger + Q&A surface; the paired iPhone is the brain (doc 04).
// Primary input: on-watch dictation → text over WatchConnectivity.
import SwiftUI

@main
struct SaturdayWatchApp: App {
    @State private var phone = WatchPhoneLink()

    var body: some Scene {
        WindowGroup {
            AskView()
                .environment(phone)
        }
    }
}
