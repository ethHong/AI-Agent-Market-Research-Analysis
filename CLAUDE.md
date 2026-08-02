# CLAUDE.md — Saturday

## What this repo currently is

This repo started as an AI-agent market research archive (`Research - Slides/`, README).
It now also hosts the planning and (eventually) the code for **Saturday**, a new paid
iOS + watchOS app. Planning docs live in `docs/saturday/`. Do not modify the legacy
research slides.

## Product: Saturday

**One-liner:** A session-based, on-device AI assistant for iPhone + Apple Watch that
listens *with* you during a conversation or meeting and, when you ask it something
mid-conversation, answers using the context of what was just said — like Jarvis/Friday
("Saturday" is named after Friday), but private and fully offline.

**Core loop:**
1. User starts a **listening session** (Action Button, App Shortcut, widget, or Watch).
2. Saturday transcribes speech on-device into a **rolling transcript buffer**.
3. User asks a question mid-conversation (wake phrase during session, or tap/raise on Watch).
4. On-device LLM answers using the recent transcript as context.
5. Optional tool actions: create calendar events/reminders, draft messages, find nearby places.

**Hard product constraints (decided — do not re-litigate):**
- **No cloud LLM APIs.** All ASR + LLM inference is on-device. This is the product's
  privacy moat and its cost structure (zero marginal cost → paid-upfront pricing works).
- **Session-based listening, not always-on.** iOS forbids 3rd-party always-on wake words;
  background continuous recording is an App Store rejection risk. Saturday listens only
  during an explicit user-started session (recording continues with screen locked via the
  `audio` background mode). A custom wake phrase ("Hey Saturday") is allowed *within* an
  active session via local keyword spotting.
- **Watch is a first-class surface from v1.** The Watch is the quick-activation + Q&A UI;
  the paired iPhone is the brain and the session recorder (ASR + LLM). Primary watch input
  is on-watch dictation → text over WatchConnectivity (robust); chunked audio streaming to
  the phone is the higher-fidelity experiment (5–30 s lag risk — see research doc 02). No
  LLM or SpeechTranscriber on the Watch itself (memory-infeasible / API absent).
- **Hybrid LLM strategy.** Primary: Apple **Foundation Models framework** (iOS 26+, free,
  on-device ~3B, built-in tool calling / guided generation) on Apple Intelligence devices.
  Fallback/quality option: bundled or downloadable open-source model via **MLX Swift**
  (e.g. Qwen3-4B 4-bit) for older devices or when higher quality is needed.
- **English first; Korean is a fast-follow** (keep it in mind when picking models/ASR —
  prefer stacks with a credible Korean path: Foundation Models + SpeechTranscriber both
  support `ko`, Qwen3 is Apache-2.0, HyperCLOVA X SEED is free <10M MAU. EXAONE/Kanana are
  non-commercial licenses — unusable in a paid app without a deal).
- **Monetization: paid upfront** (buy-once). No subscription, no server costs. "No cloud,
  no subscription" is the marketing position.

## Target stack (planned)

- Swift / SwiftUI, Xcode, iOS 26+ primary target (Foundation Models requires it),
  graceful degradation path researched in docs.
- watchOS app: SwiftUI + WatchConnectivity (audio chunk streaming to phone).
- ASR: Apple SpeechAnalyzer/SpeechTranscriber (iOS 26) primary; WhisperKit as
  fallback/quality option. On-device only.
- LLM: FoundationModels framework (`LanguageModelSession`, `Tool` protocol,
  `@Generable` guided generation); MLX Swift (`mlx-swift-examples` / `MLXLLM`) for the
  open-model path.
- Wake-phrase-in-session: lightweight keyword spotting (Core ML / openWakeWord-style) +
  VAD (Silero or Apple VAD) — research notes in docs.
- Tools/actions: EventKit (calendar/reminders), MKLocalSearch (nearby places, no API key),
  MFMessageComposeViewController (message drafts — user must tap send; auto-send is
  impossible on iOS, design around it), App Intents for activation surfaces.
- TTS: AVSpeechSynthesizer to start; evaluate on-device neural options later.

## Repo layout

```
CLAUDE.md                  ← this file
AGENTS.md                  ← guidance for Codex/other agents (co-development)
HANDOFF.md                 ← running baton log between agents/owner — read before working
README.md                  ← legacy market-research README (leave as-is)
Research - Slides/         ← legacy market research (leave as-is)
docs/saturday/
  00-product-brief.md      ← concept, decisions, positioning, pricing, privacy pillars
  01-research-ondevice-llm.md    ← on-device LLM/ASR feasibility research
  02-research-audio-listening.md ← listening/session/App Store constraints research
  03-research-integrations-market.md ← system integrations + competitive landscape
  04-architecture.md       ← system architecture (phone/watch, pipelines, tool calling)
  05-roadmap.md            ← phased build plan (M0…)
  06-features-ux-differentiation.md ← feature set, workflows, Siri/ChatGPT differentiation
app/
  README.md                ← layer rules + Mac setup checklist
  SaturdayCore/            ← tested pure-Swift core (builds on Linux — keep it that way)
  SaturdayApp/             ← iOS shell (⚠️ unverified until compiled in Xcode)
  SaturdayWatch/           ← watchOS thin client (⚠️ unverified)
  project.yml              ← XcodeGen spec
```

## Working conventions for Claude

- **Handoff protocol**: this repo is co-developed with Codex and the owner. Read
  `HANDOFF.md` top entry before working; prepend an entry after substantive work.
  `AGENTS.md` hard rules (core-layer purity, test-before-push, privacy invariants,
  unverified-headers) apply to Claude too.
- Big builds/tests can run here: a Swift 6.1 Linux toolchain works for
  `app/SaturdayCore` (`swift test`). iOS/watchOS shells compile only in Xcode on
  the owner's Mac — mark such work unverified rather than claiming it works.
- Keep docs in English (product decision: English-first), concise and decision-oriented;
  mark open questions explicitly in an "Open questions" section rather than burying them.
- When feasibility claims matter (memory limits, App Store policy, API availability),
  cite sources with URLs in the research docs and mark uncertainty. Re-verify anything
  older than ~6 months before building on it — this space moves fast.
- Development branch: `claude/saturday-ai-assistant-app-bfbo3x`. Commit with clear
  messages; push with `git push -u origin <branch>`.

## Key open risks (see docs for detail)

1. Foundation Models **4,096-token fixed context** — transcript compaction is mandatory
   (TN3193 pattern); QA quality over compacted long transcripts unproven.
2. WatchConnectivity audio streaming latency/reliability (5–30 s lag risk; dictation-text
   path is the safe primary).
3. Battery/thermals of long sessions (~7–12%/hr est. mic+ASR; sustained LLM decode
   throttles 40–60% after ~10 min — answer in short bursts).
4. App Store review posture on conversation recording UX (2.5.14 consent/indication,
   2.5.4 audio-background-mode gray zone, 5.1.2) — frame as user-initiated note-taker.
5. Audio-session interruptions (calls/Siri) cannot be resumed from background — needs
   "tap to resume" notification UX.
6. Wake-phrase spotting: no system-wide wake word ever; in-session KWS (openWakeWord/DIY)
   or transcript hotphrase; Porcupine costs ~$6k/yr.
