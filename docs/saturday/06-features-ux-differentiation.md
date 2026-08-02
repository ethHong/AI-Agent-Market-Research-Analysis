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

### vs ChatGPT / Claude (the other front)

Chat apps are **destinations**: you stop what you're doing, open them, and *explain the
situation* before you can ask. Saturday was already in the room — **zero context
re-entry** is the differentiator no chatbot can copy from inside a chat UI:

| | ChatGPT/Claude (incl. voice) | Saturday |
|---|---|---|
| Context | Only what you type/say to it | Heard the whole room already |
| Mid-conversation use | Break the flow, explain, then ask | 3 s wrist glance, zero explanation |
| Posture | A 1:1 session *with the AI* | A quiet aide *inside a human conversation* |
| iOS actions | Can't touch EventKit/Reminders | Native calendar/reminders/places/drafts |
| Privacy | Conversation goes to their servers | Never leaves the phone; airplane-mode demo |

**Where we lose — and therefore don't fight:** open-ended knowledge Q&A and long-form
generation. A 3–4B on-device model loses that comparison every time. Consequence for
**W4 (sessionless mode)**: frame and market it as **quick actions** (calendar, reminders,
places, drafts — things ChatGPT can't do on iOS), *not* as a general chat mode. The UI
should nudge sessionless general-knowledge questions toward web-lookup-grounded short
answers, never long chatbot conversations.

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

### W4 — Quick actions, no session (deliberately narrow)
No active session: Saturday works as a push-to-talk **action** assistant — calendar,
reminders, places, message drafts (the things ChatGPT can't do on iOS), plus short
web-lookup facts. It exists so the app is useful daily, keeping it on the Action Button
so sessions actually get started when they matter. **Not** a general chat mode: no
long-form generation, no open-ended knowledge conversations — that's ChatGPT's turf and
a 3–4B model loses the comparison (see §1). UI keeps answers short and action-shaped.

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
being-a-search-engine, phone settings, timers-as-identity, open-ended chatbot companion,
image generation. Every one of these is Siri/ChatGPT home turf and dilutes the "it was
in the room" identity. The tool layer exists to serve conversation outcomes (calendar,
reminders, places, drafts) — not to become a junk drawer.

**Web lookup is allowed as a *tool*, not an identity** (owner decision 2026-08-01):
when a conversation-grounded question needs outside facts, the LLM may call
`WebLookupTool` — but Saturday never becomes a general search box. See §8a.

## 8a. WebLookupTool design — general web search, no API keys, no servers

Owner decision (2026-08-01): Saturday needs **general web search**, ChatGPT/Claude-style
— "general information questions must work," not just encyclopedia lookups.

Constraint check: "no cloud" means **LLM inference** is on-device; networking per se is
already in the product (MKLocalSearch). The line to hold is: **transcript never leaves
the device — only a distilled query string does.** Cloud assistants search via *their
servers calling paid search APIs*; serverless Saturday must have the phone talk to a
search engine directly — which narrows the keyless options to essentially one.

- **Pipeline (mini browsing, all orchestration on-device):**
  1. LLM composes a minimal search query (never transcript text).
  2. **DuckDuckGo HTML endpoint** (`html.duckduckgo.com` / `lite.duckduckgo.com`) →
     parse titles/snippets/URLs. This is the general-web workhorse — the only viable
     keyless search. Both endpoints implemented as fallbacks for each other.
  3. Snippets often suffice for quick facts → answer directly from them.
  4. If not: fetch **top 1–2 result pages** directly on the phone, run reader-mode
     text extraction, LLM-compact each page — the 4,096-token window forces
     snippet-first, fetch-few, compress-hard behavior (no 10-tab browsing).
  5. On-device LLM synthesizes the answer, citing source names/domains.
  - *Wikipedia/Wikidata REST API* stays as a supplementary structured source (stable,
    ToS-clean, great for entity/term lookups) — but it is not the primary path.
- **Honest quality bar:** this will not match ChatGPT search (their server-side search
  stack + 100B-class models). It covers "look that up for me" mid-conversation facts;
  the UI should present it as lookup, not research.
- **Risks & mitigations:** DDG HTML is unofficial — layout changes or rate-limiting/
  CAPTCHA can break it (ToS-gray). Mitigate: isolated thin parser (expect to patch in
  app updates), dual endpoints, polite request rate, graceful "search unavailable"
  degradation to `🧠` + hedge. No key to steal, no quota to pay.
  Rejected alternatives: Brave/Bing/Google APIs (embedded keys = cost + abuse risk,
  conflicts with buy-once pricing); self-hosted SearXNG or any proxy (violates
  zero-server rule); Google HTML scraping (aggressively blocked).
- **Privacy contract:** opt-in toggle ("Allow web lookups"); request contains only the
  LLM-composed query terms; answers carry the third source label — `🌐 From the web` —
  alongside `🗣` / `🧠`.
- **Offline behavior:** airplane mode → tool reports unavailable → §6 honest refusal
  ("can't check the web right now").
- Roadmap: M3 (tool layer) behind the opt-in toggle — DDG search+snippets first, page
  fetch/extraction second, Wikipedia supplement third.

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

## 9. Product decisions (confirmed with owner, 2026-08-01)

1. **Query trigger**: Watch-tap + push-to-talk are the v1 primary triggers; the wake
   phrase ships as an off-by-default beta toggle (the word "Saturday" collides with
   dates in normal speech; KWS tuning is deferred risk).
2. **Advise/Reality-check (W3)**: **in v1 with a "beta" label** — source labels and
   hedging UX (§6) are mandatory, private surfaces only.
3. **W4 sessionless assistant mode**: **in v1** — daily-use retention keeps the Action
   Button assignment alive; marginal cost is low since the tool layer exists anyway.
4. **Proactive commitment capture**: **in v1**, end-of-session card only — falls out of
   the `@Generable` action-item extraction pass nearly for free.

### Still open
- **Summary templates per tag**: Meeting + Lecture at launch (assumed, not yet confirmed).
- Wake-phrase final wording if/when the beta graduates ("Hey Saturday" vs custom).
