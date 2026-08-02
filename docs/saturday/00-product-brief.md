# Saturday — Product Brief

*Status: v0.1 draft — decisions confirmed with owner (2026-08-01)*

## Concept

Saturday is a paid iPhone + Apple Watch AI assistant, named after Jarvis's successor
"Friday." Unlike Siri or chat apps, Saturday's signature ability is **contextual
listening**: you start a session before or during a real-world conversation (meeting,
lecture, negotiation, dinner debate), Saturday quietly transcribes on-device, and when
you ask it something — mid-conversation, from your wrist — it answers with full awareness
of what was just said.

> "What was the number he just quoted?" · "Is that claim actually true?" ·
> "Add what we just agreed to my calendar." · "Draft a follow-up text to her about this."

Everything runs on-device: speech recognition and the language model. No audio, no
transcript, no query ever leaves the phone. That is simultaneously the privacy story,
the App Store review story, and the business model (zero marginal cost → buy-once).

## Confirmed decisions

| Area | Decision | Rationale |
|---|---|---|
| Platforms | iPhone + Apple Watch from v1; Watch is a headline feature | Wrist activation/answers is the differentiator that justifies a paid app; iPhone is the compute brain, Watch is mic + UI |
| Listening model | Session-based (explicit start/stop), not always-on | iOS platform + App Store constraint; also the honest privacy posture |
| LLM | Hybrid: Apple Foundation Models (primary) + MLX open model (fallback/quality) | Zero-cost, zero-download default; open model covers non-Apple-Intelligence devices and quality ceiling |
| ASR | On-device only (SpeechAnalyzer / WhisperKit) | Core constraint: no cloud |
| Language | English first; Korean fast-follow | Global market first; stack chosen to keep Korean viable |
| Pricing | Paid upfront (buy once) | No server costs; "no subscription" as positioning |

## Target user & jobs-to-be-done

- Professionals in back-to-back meetings: instant recall + action capture without a
  cloud recorder (many workplaces ban Otter-style cloud tools).
- Students/researchers in lectures and seminars.
- Anyone mid-conversation who wants a discreet, context-aware answer from their wrist.

**JTBD:** "While I'm in a conversation, give me a second brain that heard everything I
heard, answers instantly, and never uploads a word."

## Signature interactions

1. **Session start** — Action Button / Watch complication / double-tap → orange mic
   indicator on, discreet UI, transcription begins.
2. **Ask mid-conversation** — say the wake phrase ("Saturday, …") during an active
   session, or raise wrist + tap. Answer is shown (and optionally whispered via
   AirPods) without interrupting the room.
3. **Act** — "add that to my calendar," "remind me to send the deck," "find a sushi
   place near here for 7pm," "draft a message to Alex summarizing this."
   (iOS constraint: messages are *drafted*, user taps send.)
4. **Session end** — summary card: key points, decisions, action items; transcript
   stored locally (searchable), auto-delete policy configurable.

## Positioning

- vs **Siri**: Siri has no memory of the room's conversation; Saturday's whole premise
  is conversational context. (And LLM-Siri keeps slipping.)
- vs **ChatGPT/Claude/Gemini**: destination apps — you must stop, open them, and explain
  the situation before asking. Saturday already heard it: zero context re-entry. Plus
  native iOS actions and no-cloud privacy. We do NOT compete on open-ended knowledge
  chat (a 3–4B model loses that fight; see doc 06 anti-scope).
- vs **Otter/Granola/Plaud/Limitless**: recorders with cloud processing and/or extra
  hardware; Saturday is real-time Q&A, on-device, on hardware you already own.
- Tagline candidates: *"The assistant that was in the room."* / *"Heard everything.
  Tells no one."*

## Privacy pillars (non-negotiable, owner-confirmed)

The product must never read as a surveillance tool. Five pillars, enforced in design,
copy, and code:
1. **No always-on, as philosophy not just platform limit**: explicit start/stop; orange
   mic indicator + Live Activity always visible; background start is impossible on iOS
   and we advertise that we wouldn't want it anyway.
2. **Audio is discarded on transcription** (Granola precedent): only text is ever
   stored; no voiceprints.
3. **Forgetting is the default**: transcripts auto-delete after N days (default on);
   "ephemeral session" option keeps only the end-of-session summary.
4. **Nothing leaves the phone**: ASR + LLM on-device; web lookup is opt-in and sends
   only distilled query terms, never transcript.
5. **Consent UX**: onboarding teaches disclosure norms; framing everywhere is
   "note-taker for conversations you're part of," never ambient capture of others.

Marketing compression: *"Listens only when you ask. Forgets on your schedule. Nothing
ever leaves your phone."*

## Open questions

- Wake-phrase name collision ("Hey Saturday" false triggers on the word "Saturday" in
  normal speech — may need "Hey Sat"/custom phrase setting).
- Price point: $9.99 vs $19.99 buy-once; whether the MLX high-quality model pack is an
  IAP.
- Transcript retention default (privacy posture suggests aggressive auto-delete).
- AirPods whisper-answer UX (ducking, spatial) — v1 or v1.1.
