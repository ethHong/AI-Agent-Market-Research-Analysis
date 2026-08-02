# HANDOFF — Saturday baton log

Newest entry first. Every agent/owner session that changes the repo prepends an
entry using this template:

```
## YYYY-MM-DD — <agent/owner> — <one-line summary>
Done:            what actually happened
Verified:        what was built/tested and WHERE (Linux tests ≠ device tests)
Not verified:    known-unverified work left behind
Next:            the most valuable next steps, in order
Landmines:       things that will bite the next person if unknown
Needs owner input: open product/scope questions (or "none")
```

---

## 2026-08-02 — Claude Code (remote, Linux env) — Planning docs complete + first code drop

**Done:**
- Full planning/doc set `docs/saturday/00–06`: product brief, three research docs
  (on-device LLM/ASR, listening/App-Store constraints, integrations/market),
  architecture, roadmap, features/UX/differentiation. All product decisions in
  them are owner-confirmed (see doc 06 §9 + brief).
- `app/SaturdayCore` Swift package — the platform-independent brain:
  session state machine (incl. the no-background-resume interruption rule),
  rolling transcript + compaction policy, 4,096-token prompt assembler,
  BM25 transcript retrieval (Korean bigram support), hotphrase detector,
  LLM backend protocol + router, tool-call JSON parser, DDG search parser.
- `app/SaturdayApp` + `app/SaturdayWatch` shells: SessionManager, audio session
  controller (interruption → tap-to-resume notification), SpeechTranscriber
  wrapper, AFM backend, MLX stub, tools (calendar/reminders/places/web-lookup/
  message-draft specs), App Intents, phone↔watch connectivity, minimal SwiftUI
  UI with source-label answer cards. `app/project.yml` for XcodeGen.
- Collaboration infra: `AGENTS.md` (Codex guidance), this file.

**Verified:** SaturdayCore — 40/40 unit tests passing on Linux (Swift 6.1).

**Not verified:**
- Everything under `SaturdayApp/` and `SaturdayWatch/` — never compiled; every
  file carries an `⚠️ UNVERIFIED-ON-DEVICE` header. `SpeechTranscriberEngine`
  and `AFMBackend` were written from WWDC25 documentation and WILL need
  signature fix-ups against the real iOS 26 SDK.
- DDG parser fixtures are representative, not captured from live responses —
  capture real endpoint HTML before M3 and extend the tests.

**Next (in order):**
1. Mac session: `xcodegen generate`, compile, fix shell-layer errors, run on a
   real iPhone (needs iPhone 15 Pro+ for Foundation Models).
2. M0 spikes (docs/saturday/05-roadmap.md) — context-QA quality, locked-screen
   ASR endurance + interruption flow, watch relay latency. These are
   go/no-go gates; do them before feature work.
3. AFM `Tool` protocol bridge for the tool specs (M3 prep), Live Activity
   listening indicator (M1, App Review 2.5.14).

**Landmines:**
- Do NOT add MLX/mlx-swift as a dependency of SaturdayCore — it can't build on
  Linux and will kill the tested-core loop. Xcode-side SPM only (see MLXBackend
  header).
- Foundation Models context is 4,096 tokens TOTAL (input+output) — resist any
  "just include more transcript" change; that's what PromptAssembler budgets for.
- Audio session cannot be reactivated from background after a call/Siri
  interruption. Any "auto-resume" idea is a dead end on iOS; the notification
  flow in AudioSessionController is the legal path.
- The default hotphrase config intentionally demonstrates the "Saturday = date"
  false-positive in its tests; wake phrase stays an off-by-default beta.

**Needs owner input:** none right now — next decisions (pricing, exact wake
phrase) are post-M0.
