# Saturday — Features, Workflows & Differentiation vs Siri

*v0.1 — 2026-08-01. This is the product-design core: what Saturday does, how each
interaction flows, and why Siri can't follow.*

## 1. The differentiation thesis

Siri (even Gemini-backed 2026 Siri) is a **command executor**: you summon it, issue a
request about *your phone or the world*, it acts, it vanishes. Saturday is a
**conversation copilot**: it was *in the room with you*, so you talk to it about
*what's happening right now*.

Five moats Siri structurally cannot cross:

| # | Moat | Why Siri can't follow |
|---|---|---|
| 1 | **Conversation context.** Every answer is grounded in the rolling transcript of the last hour. | Apple will not ship ambient recording of the user's surroundings under the Siri brand — privacy positioning + all-party-consent law exposure. Siri hears 5 seconds; Saturday heard the whole meeting. |
| 2 | **Provably offline.** Airplane-mode demo; conversation data never leaves the device. | New Siri routes through cloud Gemini (~$1B/yr deal). Apple can't market "never leaves your phone" for its flagship assistant anymore — Saturday can. |
| 3 | **Session artifacts.** Every session ends with a summary, decisions, action items, and a searchable local transcript. | Siri is stateless by design; it leaves nothing behind. |
| 4 | **Discreetness.** Designed to be used *while in company*: glance at wrist, haptic, whisper in AirPods, typed queries. | Siri is an interruption — it talks over the room and takes the screen. Saturday is built to not break the conversation. |
| 5 | **One job, deep.** Conversation companion only. | Siri must be everything to everyone (timers, home, music, calls). Saturday refuses that scope (see §7) and wins its one vertical. |

**Pitch compression:** *Siri answers questions. Saturday answers your situation.*

## 2. Core primitive: the Session

Everything is designed around one object — a **Session** (a bounded stretch of real-world
conversation the user chose to share with Saturday). This framing does triple duty:
product (context = value), App Store (user-initiated, visible), legal (participant
consent).

**Session anatomy:**
- `context tag` (optional, at start): Meeting / Lecture / Interview / Casual — tunes
  summary format and answer tone.
- `focus` (optional, the power feature): a one-line brief the user gives at start —
  *"salary negotiation — track numbers and commitments"*, *"customer call — catch
  objections"*. Injected into the system prompt; makes every answer and the final
  summary purpose-aware. Siri has no equivalent concept at all.
- `rolling transcript` (timestamped utterances) + `live compact summary` (LLM-maintained).
- `artifacts` (produced at end): summary, decisions, action items, captured items.

## 3. Query taxonomy — what you can ask mid-conversation

Design each class explicitly; they have different retrieval needs, answer shapes, and
surfaces. (R = needs transcript retrieval beyond the recent tail; see §8.)

| Class | Example | Answer shape | Surface |
|---|---|---|---|
| **Recall** (R) | "What deadline did she say?" / "What was the number he quoted?" | One line, verbatim-ish, with when-said | Wrist-first |
| **Explain** | "What's EBITDA?" (term just used) / "What does that acronym mean here?" | 2–3 sentences, grounded in how it was used | Wrist or phone |
| **Catch-up** (R) | (came back from bathroom) "What did I miss?" | Bulleted micro-summary of last N min | Phone card |
| **Synthesize** (R) | "What have we actually agreed on so far?" / "Summarize her position" | Structured bullets | Phone card |
| **Advise** (whisper mode) | "What should I ask next?" / "Is their offer better than the last one?" | 1–2 suggestions, hedged | AirPods/wrist, private |
| **Reality-check** | "Does that claim sound right?" | Hedged: grounded in transcript + model knowledge, labeled (§6) | Private surfaces only |
| **Capture** | "Note that." / "Remember this idea." | Confirmation haptic + saved snippet | Wrist |
| **Act** (tools) | "Put that lunch on my calendar" / "Remind me to send the deck" / "Find a sushi place near here for 7" / "Draft a text to Alex about this" | Pre-filled system sheet or confirm card | Phone (watch confirms simple ones) |

Two details that make these feel magical and Siri-impossible:
- **Anaphora resolution against the room**: "add *that* to my calendar," "text Alex about
  *this*" — *that/this* resolve against the transcript, not the screen. This is the
  single most demo-able differentiator.
- **Deixis of time**: "the number he said *a few minutes ago*" — timestamped transcript
  makes fuzzy time references resolvable.

## 4. Workflows (end-to-end)

### W1 — Meeting copilot (hero workflow)
1. Walking into the room: Action Button (or Watch complication) → session starts with
   tag "Meeting", optional spoken focus ("budget review — track who owns what").
2. Phone goes face-down in pocket/table; Live Activity shows listening state; Watch shows
   a subtle waveform.
3. Mid-meeting, user murmurs "Saturday, what did Jin say the Q3 target was?" or taps the
   Watch and dictates. Answer appears on wrist in ~2 s; nobody's flow breaks.
4. "Saturday, note that we agreed to ship Oct 10" → haptic confirm, captured.
5. Meeting ends → stop from Watch/phone → summary card: TL;DR, decisions, action items
   ("You owe: send deck by Fri" → one-tap convert to Reminder / Calendar).
6. That evening: "What did we decide about the vendor?" — post-session Q&A over the
   stored transcript.

### W2 — Lecture/talk companion
Start with "Lecture" tag → mostly Explain + Catch-up + Capture ("note that formula").
End artifact: study-note-shaped summary. (Same engine, different summary template.)

### W3 — Discreet advisor (negotiation, interview, sales call)
Focus set at start; queries flow through AirPods whisper or typed input
(**Silent Mode**: type the question, read the answer — zero audio footprint).
Advise/Reality-check classes shine here. This is the workflow no big-tech assistant
will ever ship — too spicy for a platform brand, perfect for a $30 tool.

### W4 — Instant capture, no session (degraded but useful)
No active session: Saturday still works as a normal push-to-talk assistant for Act/
Explain queries (calendar, reminders, places, drafts). Honest Siri-parity mode — it
exists so the app is useful daily, keeping it on the Action Button so sessions actually
get started when they matter. (Without W4, users un-assign the button and the moat
features never get used.)

### W5 — Post-session recall (the memory dividend)
Local, searchable session library. "Ask your week": *"what did I promise anyone this
week?"* → scans action items across sessions. This compounds: the longer you use
Saturday, the more irreplaceable it gets. (Cross-session Q&A is post-1.0; the library +
per-session Q&A is v1.)

## 5. Answer surfaces & discreetness design

Discreetness is a *feature axis Siri doesn't have* — invest UI here, not in flashy
animation:
- **Wrist card**: ≤ 140 chars target answer; haptic patterns encode answer type
  (confirm / info / "long answer on phone").
- **AirPods whisper**: TTS at reduced level, ducks only user's ear, never the room
  speaker. Auto-selected when AirPods active + session tag is Meeting/Interview.
- **Silent Mode**: typed query field on phone + Watch scribble; answers text-only.
  No audio in, no audio out.
- **Never speaks unprompted.** Proactive ideas (see §9) surface as end-of-session cards
  or gentle badge counts — a copilot that interrupts the room is dead on arrival.

## 6. Trust UX (the on-device honesty contract)

A 3–4B on-device model has weak world knowledge. Instead of hiding that, productize it:
- **Source labels on every answer**: `🗣 From this conversation` / `🧠 General knowledge`
  / mixed. Transcript-grounded answers (the moat) are the reliable ones; model-knowledge
  answers get an explicit "may be off — I'm offline" hedge.
- **Tap-to-verify**: every Recall answer links to the transcript moment (timestamp) it
  came from. Verifiability beats eloquence for trust.
- **Refusal style**: "That wasn't said in this session, and I can't check the web" is a
  *feature* sentence — it reinforces the privacy story every time it appears.

## 7. Anti-scope (what Saturday refuses to be)

Explicitly out, forever or until dominance in the core: music control, smart home,
general web search, phone settings, timers-as-identity, open-ended chatbot companion,
image generation. Every one of these is Siri/ChatGPT home turf and dilutes the "it was
in the room" identity. The tool layer exists to serve conversation outcomes (calendar,
reminders, places, drafts) — not to become a junk drawer.

## 8. Architecture implication: transcript RAG inside 4k tokens

The query taxonomy forces one addition to `04-architecture.md`: Recall/Catch-up/
Synthesize queries reference content that may be 40 minutes old — outside the verbatim
tail that fits Foundation Models' 4,096-token window. So the query orchestrator needs
**on-device retrieval over the full session transcript**:
- Index utterances incrementally (keyword/BM25 first; NLEmbedding vectors if needed).
- On query: retrieve top-k relevant utterance spans (with timestamps) + live compact
  summary + last ~1 min verbatim → assemble the 4k prompt.
- This also powers W5 (post-session and cross-session search) with the same index.
Effort is modest (SQLite FTS5 is enough for v1) and it converts the 4k limitation from
a product ceiling into an implementation detail.

## 9. Open product questions (discuss before M1)

1. **Wake phrase ergonomics**: "Saturday" appears in normal speech (dates!). Options:
   two-word phrase ("Hey Saturday"), user-customizable phrase, or lean harder on
   Watch-tap/push-to-talk and treat wake phrase as beta. *Recommendation: ship
   Watch-tap + push-to-talk first; wake phrase behind a toggle.*
2. **Advise/Reality-check scope in v1**: highest wow, highest hallucination risk on a
   3B model. Ship in v1 behind "beta" label, or hold for the MLX 4B quality tier?
3. **W4 (sessionless assistant mode)**: include in v1 for daily-use retention, or is it
   scope creep that delays the moat?
4. **Proactive capture**: auto-detect commitments ("I'll send it Friday") and offer
   reminders at session end — v1 or v1.1? (Live interruptions are ruled out; this is
   end-of-session only.)
5. **Summary templates per tag**: how many at launch? (Meeting + Lecture seems enough.)
