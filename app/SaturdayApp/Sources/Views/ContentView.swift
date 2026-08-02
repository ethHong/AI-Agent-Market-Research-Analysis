// ⚠️ UNVERIFIED-ON-DEVICE: authored off-Mac; needs Xcode compile + device test.
// v1 UI is deliberately minimal: session state, live tail, ask bar, answer card.
// Live Activity (Dynamic Island "listening" indicator) is TODO(M1) — it doubles
// as the App Review 2.5.14 visible-indication requirement.
import SwiftUI
import SaturdayCore

struct ContentView: View {
    @Environment(SessionManager.self) private var session
    @State private var questionText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                stateBanner
                transcriptPreview
                Spacer()
                if let answer = session.currentAnswer {
                    AnswerCardView(answer: answer)
                }
                askBar
            }
            .padding()
            .navigationTitle("Saturday")
            .toolbar { sessionButton }
        }
        .onReceive(NotificationCenter.default.publisher(for: .saturdayStartSession)) { _ in
            Task { await session.startSession() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .saturdayEndSession)) { _ in
            Task { await session.endSession() }
        }
    }

    private var stateBanner: some View {
        Group {
            switch session.machineState {
            case .idle, .ended:
                Label("Not listening", systemImage: "mic.slash")
                    .foregroundStyle(.secondary)
            case .listening:
                Label("Listening — audio never leaves this phone", systemImage: "waveform")
                    .foregroundStyle(.green)
            case .answering:
                Label("Thinking…", systemImage: "brain")
            case .interrupted:
                Button {
                    Task { await session.resumeAfterInterruption() }
                } label: {
                    Label("Paused by a call — tap to resume", systemImage: "exclamationmark.circle")
                        .foregroundStyle(.orange)
                }
            }
        }
        .font(.callout)
    }

    private var transcriptPreview: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(session.liveTranscriptTail) { utterance in
                    Text(utterance.text)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxHeight: 220)
    }

    private var askBar: some View {
        HStack {
            TextField("Ask about this conversation…", text: $questionText)
                .textFieldStyle(.roundedBorder)
                .onSubmit(submit)
            Button(action: submit) {
                Image(systemName: "arrow.up.circle.fill").font(.title2)
            }
            .disabled(questionText.isEmpty)
        }
    }

    private var sessionButton: some View {
        Button {
            Task {
                if session.machineState == .listening || session.machineState == .interrupted {
                    await session.endSession()
                } else {
                    await session.startSession()
                }
            }
        } label: {
            Image(systemName: session.machineState == .listening ? "stop.circle.fill" : "record.circle")
        }
    }

    private func submit() {
        let question = questionText
        questionText = ""
        Task { await session.ask(question) }
    }
}

struct AnswerCardView: View {
    let answer: SessionManager.Answer

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(answer.text).font(.body)
            HStack {
                sourceLabel
                Spacer()
                if let time = answer.sourceTime {
                    // Tap-to-verify entry point (doc 06 §6). TODO(M1): jump to moment.
                    Text("at \(PromptAssembler.timestamp(time))")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var sourceLabel: some View {
        let (icon, text): (String, String) = switch answer.source {
        case .conversation: ("quote.bubble", "From this conversation")
        case .generalKnowledge: ("brain", "General knowledge — may be off")
        case .web: ("globe", "From the web")
        case .mixed: ("square.stack", "Conversation + knowledge")
        }
        return Label(text, systemImage: icon)
            .font(.caption).foregroundStyle(.secondary)
    }
}
