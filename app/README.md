# Saturday — app code

Two layers with different verification status:

| Layer | Path | Builds/tests where | Status |
|---|---|---|---|
| **SaturdayCore** | `SaturdayCore/` | Linux, macOS, Xcode | ✅ 40 unit tests passing (run on Linux CI/agent env) |
| **App shells** | `SaturdayApp/`, `SaturdayWatch/` | Xcode only (iOS 26 SDK) | ⚠️ authored off-Mac, **never compiled** — expect fix-ups |

## Layer rules (keep these invariants)

- `SaturdayCore` is the platform-independent brain: transcript buffer/compaction,
  4k-token prompt assembly, BM25 retrieval, session state machine, hotphrase
  detection, tool-call parsing, DDG search parsing. **No UIKit / SwiftUI /
  AVFoundation / FoundationModels imports here, ever** — that's what keeps it
  testable off-Mac. New pure logic goes here, with tests.
- App shells are thin adapters: audio, ASR, FoundationModels, EventKit/MapKit,
  WatchConnectivity, SwiftUI. Files carry an `⚠️ UNVERIFIED-ON-DEVICE` header
  until compiled/tested on hardware — remove the header when verified and log it
  in `/HANDOFF.md`.

## Running core tests

```bash
cd app/SaturdayCore
swift test        # needs Swift 6.1+ toolchain (Linux tarball or Xcode)
```

## First Mac session checklist

1. `brew install xcodegen && cd app && xcodegen generate` → open `Saturday.xcodeproj`,
   set signing team.
2. Compile — reconcile `SpeechTranscriberEngine.swift` and `AFMBackend.swift`
   against the real iOS 26 SDK signatures (both flagged; they were written from
   WWDC session documentation).
3. Run M0 spikes (docs/saturday/05-roadmap.md): context-QA quality, locked-screen
   ASR endurance, watch relay latency. These decide the architecture, do them
   before building more features.
4. `MLXBackend` is a stub on purpose: the MLX Swift dependency can't build on
   Linux, so add it via Xcode's SPM UI only — never to `SaturdayCore/Package.swift`.
