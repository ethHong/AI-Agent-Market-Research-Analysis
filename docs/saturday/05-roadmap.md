# Saturday — Roadmap (v0.1 draft)

Phased so every milestone kills the biggest remaining risk first. Solo-dev sized;
each milestone ends with something runnable on real hardware.

## M0 — Feasibility spikes (1–2 weeks, throwaway code)
Goal: prove the three scariest assumptions on a real iPhone (and Watch if available).
1. **Spike A — context Q&A quality:** feed FoundationModels a 10-min meeting transcript
   (canned) + a question; judge answer quality, context limits, latency. Repeat with
   MLX Qwen3-4B 4-bit. *Kill criterion:* if both are unusable on-device, product pivots.
2. **Spike B — live ASR loop:** AVAudioEngine → SpeechAnalyzer streaming transcription
   for 30+ min with screen locked (audio background mode). Measure battery, lag, accuracy.
   Include the interruption case: incoming call mid-session → verify no background
   resume is possible → "tap to resume" notification flow.
3. **Spike C — Watch relay, both paths:** (a) on-watch dictation → text via
   WatchConnectivity (expected-good baseline); (b) chunked AAC audio → phone ASR —
   measure end-to-end latency, drop behavior, reachability flaps. Decide v1 watch input
   mode from data.

## M1 — Core loop on iPhone (3–4 weeks)
- Session manager + rolling transcript buffer + compaction summarizer.
- Ask flow: hold-button push-to-talk first (wake phrase deferred), answer card + TTS.
- LLMBackend abstraction with AFM primary; MLX behind a debug flag.
- Local transcript store with auto-delete.
- **Exit demo:** hour-long podcast playing in the room; ask "what did they say about X
  five minutes ago" and get a correct answer, offline.

## M2 — Watch surface (2–3 weeks)
- watchOS app: complication + App Intent start/stop, mic streaming to phone,
  answer cards + haptics on wrist.
- Session handoff and reconnect robustness (Bluetooth drops).

## M3 — Actions/tools (2–3 weeks)
- CalendarTool, ReminderTool, PlacesTool (MKLocalSearch), MessageDraftTool —
  confirm-before-commit UX.
- Post-session summary card: decisions + action items (`@Generable` structured output),
  including **commitment detection** ("I'll send it Friday" → one-tap reminder offer)
  on the end-of-session card (decided: v1).
- **W4 sessionless assistant mode** (decided: v1): same ask flow + tools without an
  active session — the daily-use surface that keeps the Action Button assigned.

## M4 — Wake phrase + polish (2–3 weeks)
- In-session wake phrase as **off-by-default beta toggle** (decided): transcript
  hotphrase first, KWS model only if needed; VAD gating for battery.
- **Advise/Reality-check "beta"** (W3, decided: v1): source labels + hedging UX,
  private surfaces (wrist/AirPods/Silent Mode) only.
- Interruption handling hardening (calls, Siri, route changes), AirPods answer mode.
- MLX model download flow for non-Apple-Intelligence devices.

## M5 — Ship prep (2 weeks)
- Paid-app store listing; privacy nutrition labels; purpose strings; review notes
  explaining session-based recording + consent UX (biggest review risk — prepare a
  demo video for the reviewer).
- Onboarding: consent education ("recording laws vary; you're responsible for
  local-consent rules"), mic/speech permissions, pricing page copy.
- TestFlight beta with meeting-heavy users.

## Deferred (post-1.0)
- Korean language pack (ASR + prompt + model eval — EXAONE/Qwen path).
- Speaker diarization ("what did *Sarah* say about the budget?").
- Cross-session memory ("what did we decide last week?") with on-device search.
- Mac companion (same engine, menu bar).
- Subscription-free paid upgrade tiers (model pack IAP) if needed.

## Solo-dev calendar estimate
Roughly 3–4 months of focused evenings/weekends to TestFlight, assuming M0 passes.
