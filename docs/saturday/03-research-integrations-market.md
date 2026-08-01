# Research: iOS System Integrations & Market Landscape

*Research date: 2026-08-01. Re-verify anything older than ~6 months before building on it.*

## Part A — iOS System-Integration Capabilities for Assistant Actions

### A1. Calendar (EventKit / EventKitUI)

- **EventKit** (`EKEventStore`) gives full programmatic read/write of calendar events. iOS 17 replaced the old single permission with **granular tiers** ([Apple TN3153](https://developer.apple.com/documentation/technotes/tn3153-adopting-api-changes-for-eventkit-in-ios-macos-and-watchos)):
  - `requestFullAccessToEvents()` — read + write all events. Info.plist key: `NSCalendarsFullAccessUsageDescription`.
  - `requestWriteOnlyAccessToEvents()` — app can **add** events but never read existing ones. Info.plist key: `NSCalendarsWriteOnlyAccessUsageDescription` ([forum confirmation](https://developer.apple.com/forums/thread/742809); the old `requestAccess(to:)` is deprecated — [expo issue #24343](https://github.com/expo/expo/issues/24343)). Ideal minimal-privacy tier for "add this to my calendar."
  - **Zero-prompt add**: on iOS 17+, presenting **`EKEventEditViewController`** (EventKitUI) lets the user save an event **without any permission prompt** — the system sheet runs out-of-process ([WWDC23 sample](https://github.com/gromb57/ios-wwdc23__AccessingCalendarUsingEventKitAndEventKitUI)). Best assistant default: LLM pre-fills the event, user confirms in the sheet.
- **Implication**: "What's on my calendar?" requires full access; "add lunch tomorrow at 1" needs only write-only or no permission (EventKitUI). Design the permission ladder accordingly.

### A2. Reminders

- Also EventKit: `EKReminder` + `requestFullAccessToReminders()` / `NSRemindersFullAccessUsageDescription`. **No write-only tier for reminders** (TN3153) — creating a reminder requires full reminders access. Supports due dates, lists, priorities, completion. This is what Perplexity's iOS assistant uses (see B1).

### A3. Messages & Email — the hard wall

- **No third-party app can send an SMS/iMessage programmatically.** Only path: **`MFMessageComposeViewController`** (MessageUI) — app pre-fills recipients + body, **user must tap Send**; the app can't modify content after presentation and never learns what was sent ([Apple docs](https://developer.apple.com/documentation/messageui/mfmessagecomposeviewcontroller); background sending explicitly unsupported per Apple QA1944 — [forum thread](https://developer.apple.com/forums/thread/42310)). Check `canSendText()` first.
- **Email**: identical model via `MFMailComposeViewController`. Programmatic send only via your own server/SMTP — conflicts with no-cloud positioning — or open `mailto:`.
- **Shortcuts workaround**: the Shortcuts "Send Message" action can send without a confirmation tap when run inside a user-created **personal automation** with "Ask Before Running" off (or with the action's confirmation disabled). An app can launch a shortcut via `shortcuts://run-shortcut?name=...` (foregrounds Shortcuts) or donate **App Intents** the user wires into their own shortcuts. Framing for Saturday: a one-time "Saturday helper shortcut" setup enables near-hands-free sending, but it's user-configured and brittle. *(Unverified nuance: exact confirmation behavior of Shortcuts automations has shifted across iOS versions — re-test on shipping iOS 26.)*

### A4. Local Search / Nearby Places (MapKit + CoreLocation)

- **`MKLocalSearch`** — natural-language POI search with **no API key and no usage billing** for native apps; Apple's docs list availability down to iOS 6.1 and **watchOS 1.0** ([MKLocalSearch](https://developer.apple.com/documentation/mapkit/mklocalsearch)). Use `naturalLanguageQuery` + an `MKCoordinateRegion` around the user. Major cost advantage vs. Google Places for a buy-once app.
- **`MKLocalPointsOfInterestRequest`** (iOS 13+) — category-filtered nearby POIs (`.cafe`, `.evCharger`, …); `MKLocalSearchCompleter` for typeahead.
- **Directions**: `MKMapItem.openInMaps(launchOptions:)` with `MKLaunchOptionsDirectionsModeKey` hands off to Apple Maps turn-by-turn; `MKDirections` computes routes/ETAs in-app.
- **CoreLocation tiers**: When-In-Use vs Always; precise vs approximate (iOS 14+, with temporary-full-accuracy requests). When-In-Use suffices for a voice assistant.

### A5. Contacts, Calls, Music, Home, Cross-App

- **Contacts**: `CNContactStore` (`NSContactsUsageDescription`); iOS 18 added a **limited-access** tier (user grants a subset) — assume partial grants; `CNContactPickerViewController` needs no permission. Needed to resolve "text Mom."
- **Phone calls**: `tel:` URL → system Call/Cancel confirmation; no silent dialing. `facetime:` similar.
- **Music**: `MPMusicPlayerController.systemMusicPlayer` can play/pause/skip/queue **Apple Music** (needs `NSAppleMusicUsageDescription`; library/queueing via MusicKit). Spotify only via its SDK / `spotify:` scheme; no generic "control whatever's playing" API for other apps' audio.
- **HomeKit**: `HMHomeManager` gives real device/scene control with entitlement + permission — one of the few domains where a third-party assistant can act like Siri.
- **Opening/driving other apps**: URL schemes + universal links (declare schemes in `LSApplicationQueriesSchemes` to probe installability). **Critical limitation**: iOS 18 App Intents / Apple Intelligence "assistant schemas" expose app actions **to Siri/Spotlight/Shortcuts** ([WWDC24 "Bring your app to Siri"](https://developer.apple.com/videos/play/wwdc2024/10133/), [App Intents docs](https://developer.apple.com/documentation/appintents), [WWDC26 App Schemas session](https://developer.apple.com/videos/play/wwdc2026/240/)) — but there is **no public API for a third-party app to invoke another app's App Intents directly**; only the system orchestrates. Saturday's cross-app reach = system frameworks above + URL schemes + user-configured Shortcuts. This asymmetry vs. Siri is structural.

### A6. watchOS Equivalents

- **EventKit**: available on watchOS with the same granular permission APIs (TN3153 explicitly covers watchOS 10). Calendar/reminder create and query work natively on watch.
- **MapKit**: `MKLocalSearch`/`MKDirections` work on watchOS; SwiftUI `Map` is available on watchOS 10+ (older WatchKit map support was display-only — [framework list](https://docs.elementscompiler.com/Platforms/Cocoa/Frameworks/watchOSSDKFrameworks/)).
- **Messages/Email**: **MessageUI does not exist on watchOS** — no compose sheet on watch. Route the action to the paired iPhone via WatchConnectivity (phone shows the compose sheet). `tel:` on watch can initiate calls via paired phone/LTE.
- **CoreLocation** and **CNContactStore** are available on watchOS (standalone LTE included).
- **Foundation Models on watch**: Apple's docs metadata lists FoundationModels at **watchOS 27.0 (beta)** vs 26.0 for iOS/macOS/visionOS (verified from developer.apple.com docs JSON) — i.e., not on watch in the initial iOS 26 release, arriving with the watchOS 27 cycle and still beta. Watch-local LLM inference of open models is memory-infeasible; the standard architecture remains **watch = thin voice client → paired iPhone runs ASR+LLM → results/actions sync back** via WatchConnectivity. This matches Saturday's planned design.

### A7. Tool-Calling Architecture

- **Option 1 — Apple Foundation Models framework** (iOS 26+, free, ~3B on-device model, Apple Intelligence devices ≈ iPhone 15 Pro/16+): the **`Tool` protocol** is purpose-built — declare `name`, `description`, an `Arguments` struct with `@Generable`/`@Guide`, and `async call(arguments:)` that hits EventKit/MapKit/etc.; the framework handles the call loop, and guided generation eliminates JSON-parse failures ([WWDC25 session 286](https://developer.apple.com/videos/play/wwdc2025/286/), [session 301](https://developer.apple.com/videos/play/wwdc2025/301/), [developer guide](https://hackernoon.com/a-developers-guide-to-apples-foundation-models-framework-in-ios-26), [Tool deep-dive](https://blakecrosley.com/blog/foundation-models-on-device-llm)). Zero download, zero inference cost, offline. Weaknesses: 3B-class reasoning, limited context, device floor.
  - **WWDC26**: ["Bring an LLM provider to the Foundation Models framework"](https://developer.apple.com/videos/play/wwdc2026/339/) — pluggable third-party model backends behind the same API. *(Verify exact API surface against the session video; new this cycle.)*
- **Option 2 — Open models via MLX / llama.cpp** (Qwen3-4B, Llama-3.2-3B, etc.): broader device coverage and model choice; you own JSON tool-call parsing (use grammar-constrained decoding, e.g. GBNF), 2–4 GB downloads, thermals, and iOS per-app memory ceilings (increased-memory entitlement on Pro devices).
- **Recommended hybrid**: Foundation Models `Tool` layer as default, optional downloadable larger model behind the same tool interfaces; each tool is a thin Swift adapter over one system framework (CalendarTool→EventKit, RemindersTool→EventKit, PlacesTool→MKLocalSearch, MessageTool→MFMessageCompose prefill, ContactsTool→CNContactStore, HomeTool→HomeKit).

## Part B — Market / Competition Snapshot (mid-2026)

### B1. Direct competitors

| Product | State (mid-2026) | Pricing | Notes |
|---|---|---|---|
| **Siri** | Overhaul delayed ~1 year; personalized/LLM Siri targeted at **iOS 26.4, spring 2026**, with internal slips to May+ reported; Apple says "on track for 2026" ([MacRumors](https://www.macrumors.com/2025/06/12/apple-intelligence-siri-spring-2026/), [LLM Siri guide](https://www.macrumors.com/guide/llm-siri/)). Jan 2026: Apple licensed a **custom 1.2T-param Google Gemini model (~$1B/yr)** for new Siri, running in Apple's data centers ([CNBC](https://www.cnbc.com/2026/01/12/apple-google-ai-siri-gemini.html)) | Free / system | Biggest threat and biggest validation. New Siri is **cloud-Gemini-backed** → opens a real "fully on-device" differentiation lane. WWDC26 "Siri AI" rebrand reports exist only in low-tier outlets — **unverified**. |
| **ChatGPT voice** | Advanced Voice on mobile; free tier limited | Plus $20/mo (Pro $120–200/mo tiers reported; exact 2026 tiering varies — [roundup](https://suprmind.ai/hub/chatgpt/pricing/)) | No iOS system actions; conversation-only. |
| **Perplexity iOS voice assistant** | Launched Apr 2025; **uses the same public frameworks Saturday would** — EventKit reminders/calendar, MessageUI compose, `tel:`, Apple Maps handoff ([MacStories](https://www.macstories.net/stories/what-siri-isnt-perplexitys-voice-assistant-and-the-potential-of-llms-integrated-with-ios/), [help center](https://www.perplexity.ai/help-center/en/articles/11132456-how-to-use-the-perplexity-voice-assistant-for-ios)) | Free; Pro $20/mo | Closest architectural proof-of-concept, but cloud inference and no watch focus. |
| **Gemini iOS** | Lock-screen widgets + Control Center voice entry ([TechCrunch, Mar 2025](https://techcrunch.com/2025/03/03/you-can-now-talk-to-google-gemini-from-your-iphone-lock-screen/)) | Free; Google AI subs | Cloud; Google-app-centric integration. |
| **Martin** | YC-backed AI assistant via SMS/call/WhatsApp/email; calendar/inbox/tasks | ~$21–30/mo after 7-day trial; $699 lifetime promo seen ([listing](https://aiagentslist.com/agents/martin), [deal](https://www.in4tech.blog/deals/martin.ai)) — **exact current pricing unverified** | Cloud-first, channel-based. |
| **Dot (New Computer)** | **Shut down Oct 5, 2025** ([TechCrunch](https://techcrunch.com/2025/09/05/personalized-ai-companion-app-dot-is-shutting-down/)) | — | Companion, not action assistant; cautionary tale. |
| **On-device chat apps** | Private LLM (**one-time purchase**, ~$4.99–$9.99 by storefront/time — [App Store](https://apps.apple.com/jm/app/private-llm-local-ai-chat/id6448106860); exact current US price **unverified**); Fullmoon (free OSS, MLX — [App Store](https://apps.apple.com/us/app/fullmoon-local-intelligence/id6727014156)); Enclave (free + IAP); Apollo ("Powered by Liquid" — [App Store](https://apps.apple.com/us/app/apollo-ai-private-local-ai/id6448019325)); PocketPal (free OSS); LM Playground (Android, free) | Mostly free or small one-time | **None perform system actions** — local chat UIs only. Private LLM proves a paid-up-front market exists for on-device AI, at utility price points. Reliable App Store traction figures: not found. |

### B2. Ambient / wearable AI

- **Limitless** — acquired by **Meta, Dec 5, 2025**; Pendant no longer sold to new customers ([CNBC](https://www.cnbc.com/2025/12/05/meta-limitless-ai-wearable.html)).
- **Bee** — acquired by **Amazon, Jul 22, 2025**; ~$49 device + ~$19/mo; folding into Alexa (CES 2026) ([roundup](https://www.usecarly.com/blog/limitless-ai-alternatives/)).
- **Plaud** — independent survivor: NotePin **$159** / NotePin S **$179** + AI-minutes subscription tiers ([comparison](https://www.layer3labs.io/gear/plaud-note-vs-limitless)). Meeting capture, not an action assistant.
- **Friend** — relaunched mid-2026 at **$249** (up from $99) with speaker; **$10/mo** for memory beyond 30 days ([Engadget](https://www.engadget.com/2227503/that-friend-ai-wearable-you-dont-like-just-got-worse/), [TNW](https://thenextweb.com/news/friend-ai-pendant-relaunch-speaker-double-price)).
- **Omi** — ~$89, open-hardware ethos, later added a subscription ([TechCrunch](https://techcrunch.com/2025/01/08/omi-a-competitor-to-friend-wants-to-boost-your-productivity-using-ai-and-a-brain-interface)).
- **Takeaway**: 2025 consolidated ambient capture into Meta/Amazon — big tech values always-on personal context, and cloud versions carry persistent privacy backlash. The Apple Watch is the ambient wearable users already own; none of these startups build on it.

### B3. Positioning gap & willingness-to-pay

- **Nobody found doing "privacy-first, no-cloud, on-device LLM + real iOS actions + watch."** Perplexity: actions but cloud. Private LLM/Fullmoon: on-device but action-less. New Siri: system-integrated but cloud-Gemini-backed. Wearables: ambient context, big-tech clouds. The quadrant is empty as of mid-2026.
- **Caveat on "listens-with-you"**: session-based listening (as Saturday plans) is the right scope — background mic capture works via the audio background mode but is battery-heavy, always shows the mic indicator, and draws App Store scrutiny; 24/7 capture is not viable.
- **WTP signals**: AI apps' revenue-per-install (~$0.63 at 60 days) ≈ 2× the app median ([asomobile 2025](https://asomobile.net/en/blog/mobile-app-market-report-2025-monetization-ai-and-user-behavior/)); one playbook cites **41% of frequent users willing to pay ≥$15/mo** for an AI tool saving 3 h/week ([BlueAlpha](https://bluealpha.ai/playbooks/consumer-ai) — secondary source, directional only); RevenueCat 2025 shows a shift to **hybrid monetization** (~35% abandoning pure subscriptions; "subscription + credits" dominant in AI) ([RevenueCat](https://www.revenuecat.com/state-of-subscription-apps-2025)); retention is AI subscriptions' known weak spot ([TechNewsWorld](https://www.technewsworld.com/story/ai-apps-generate-revenue-but-struggle-with-retention-180236.html)).
- **Pricing read**: on-device inference = near-zero marginal cost, uniquely enabling **paid-up-front** (e.g. $19.99–$39.99, above Private LLM's utility tier) as a differentiator against the $10–20/mo subscription norm. Main strategic risk: Gemini-Siri (spring 2026 →) compresses the "better voice assistant" story — keep the wedge on **privacy/no-cloud + watch-native + user-controlled actions**, not raw capability.

## Explicitly unverified items

Martin's exact current pricing; Private LLM's current US price; Shortcuts automation confirmation behavior on shipping iOS 26; WWDC26 "Siri AI" rebrand details (low-tier sources only); Foundation Models watchOS 27 support still marked beta in Apple docs; BlueAlpha WTP statistic (unaudited secondary source).
