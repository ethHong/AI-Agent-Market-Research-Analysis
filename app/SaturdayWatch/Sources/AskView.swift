// ⚠️ UNVERIFIED-ON-DEVICE: authored off-Mac; needs paired-device testing (M2).
// TextField on watchOS surfaces dictation/scribble automatically — dictated text
// is the robust primary input path (doc 01 §3). Answers stay ≤140 chars on the
// wrist; longer ones say "details on phone" (doc 06 §5).
import SwiftUI

struct AskView: View {
    @Environment(WatchPhoneLink.self) private var phone
    @State private var question = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if !phone.isPhoneReachable {
                    Label("Open Saturday on iPhone", systemImage: "iphone.slash")
                        .font(.caption2).foregroundStyle(.orange)
                }

                HStack {
                    Button("Start", systemImage: "record.circle") { phone.startSession() }
                    Button("End", systemImage: "stop.circle") { phone.endSession() }
                }
                .font(.caption)

                TextField("Ask…", text: $question)
                    .onSubmit {
                        phone.ask(question)
                        question = ""
                    }

                if phone.isBusy {
                    ProgressView()
                } else if let answer = phone.lastAnswer {
                    Text(truncated(answer))
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                }

                if let error = phone.lastError {
                    Text(error).font(.caption2).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Saturday")
    }

    private func truncated(_ text: String) -> String {
        text.count <= 140 ? text : String(text.prefix(137)) + "… (details on phone)"
    }
}
