# Research: Ambient Conversation Listening on iOS + watchOS

*Researched 2026-08-01 via web sources. Uncertainty explicitly marked. All claims otherwise verified against the cited sources.*

**Executive summary:** A 3rd-party iOS app **cannot** be "always listening" like Siri or a hardware pendant. What it *can* do — and what every approved meeting-notes app does — is: user explicitly starts a session (Action Button / Control / widget / Siri phrase → app foregrounds → mic starts), and with the `audio` background mode the session **continues recording after screen lock or app-switch** for hours, feeding a rolling on-device transcript (iOS 26 `SpeechAnalyzer` is purpose-built for this). A custom wake phrase ("Hey Saturday") is feasible **only inside an already-running session**. Every shipped "always-on" product (Limitless, Bee, Plaud, Friend, Omi) uses **external hardware** precisely because phone-only always-on capture is impossible on iOS. App Review risk concentrates on guideline 2.5.14 (consent + visible indication) and 5.1.2 (others' personal data, third-party-AI disclosure) — manageable if the app is framed as a user-initiated conversation note-taker (Otter/Granola precedent), not an ambient recorder. This validates Saturday's session-based, on-device design.

## 1. iOS microphone rules: technical vs App Review reality

### Technically possible
- **Foreground recording**: unrestricted after mic permission. `NSMicrophoneUsageDescription` purpose string is mandatory; missing/vague strings are rejected at upload ([Apple docs](https://developer.apple.com/documentation/BundleResources/Information-Property-List/NSMicrophoneUsageDescription), [example rejection](https://github.com/ryanheise/just_audio/issues/1397)).
- **Background continuation** — Apple DTS engineer, verbatim: *"An app must be in the foreground to start recording. If the app has specified the `audio` background mode in its info.plist configuration, it can then continue recording when it moves into the background."* ([forum thread 770556](https://developer.apple.com/forums/thread/770556)). Requires an active `AVAudioSession` with `.playAndRecord`/`.record` category **before** backgrounding. This covers screen lock: foreground-started recording continues after lock — **verified**; this is how Otter/Just Press Record–class apps work.
- **Hard wall**: apps **cannot start or restart** recording from the background — since ~iOS 12.4, `setActive(true)` from background fails with "does not have the entitlement to start recording in the background" ([thread 120038](https://developer.apple.com/forums/thread/120038)). This kills wake-word-from-cold and silent auto-resume after interruptions.

### App Store Review
- **2.5.14** (exact text): *"Apps must request explicit user consent and provide a clear visual and/or audible indication when recording, logging, or otherwise making a record of user activity. This includes any use of the device camera, microphone, screen recordings, or other user inputs."* ([guidelines](https://developer.apple.com/app-store/review/guidelines/)).
- **2.5.4**: background modes only for their intended purpose. Using `audio` background mode for *recording* is a documented gray zone — some rejections reported ([thread 671366](https://developer.apple.com/forums/thread/671366), [776949](https://developer.apple.com/forums/thread/776949)) — yet voice-recorder/meeting-notes apps ship with it routinely. Approvability hinges on the recording function being the app's evident, user-visible purpose. *(Uncertainty: review outcomes are inconsistent; budget for a review round of questions.)*
- **5.1.1**: consent for data collection, accurate purpose strings, privacy policy with retention/deletion and consent withdrawal.
- **5.1.2** (updated text, relevant to Saturday): *"You must clearly disclose where personal data will be shared with third parties, **including with third-party AI**, and obtain explicit permission before doing so."* Bystanders' voices are personal data; UX copy must place recording-consent responsibility on the user. Saturday's no-cloud design sidesteps the third-party-AI clause entirely.
- **Orange mic indicator** (iOS 14+): shown in status bar/Dynamic Island whenever the mic is in use, including from background; cannot be suppressed ([Apple support](https://support.apple.com/en-us/102647)). Helps satisfy 2.5.14; makes covert operation impossible by design.

### Precedents (verified)
| Product | iOS approach |
|---|---|
| **Otter.ai** | Foreground-started in-app recording, continues in background; cannot capture carrier-call audio (blocked for all 3rd parties) — uses bots/imports for calls ([withallo](https://www.withallo.com/blog/how-to-record-phone-calls-with-otter-ai)) |
| **Granola (iPhone)** | Foreground-initiated session; transcribes on-device in real time and discards audio ([fabric.so](https://fabric.so/comparison/otter-vs-granola)) |
| **Limitless Pendant** | Dedicated hardware, own battery/storage; app is viewer/sync ([FAQ](https://help.limitless.ai/en/articles/9124757-pendant-faq)) |
| **Bee** (acquired by Amazon, Jul 2025) | $49.99 BLE wristband = tethered always-on mic; capture happens on hardware ([TechCrunch](https://techcrunch.com/2025/07/22/amazon-acquires-bee-the-ai-wearable-that-records-everything-you-say/), [GeekWire](https://www.geekwire.com/2025/amazon-is-acquiring-bee-maker-of-a-wearable-ai-assistant-that-listens-to-conversations/)) |
| **Plaud Note/NotePin** | Fully hardware-based recording; BLE 5.2/5.4 + Wi-Fi sync only ([plaud.ai](https://www.plaud.ai/products/plaud-notepin)) |
| **Friend / Omi** | BLE pendant hardware + companion app ([field review](https://mikecann.blog/posts/i-tried-the-limitless-ai-and-omi-ai-so-you-dont-have-to)) |

**Conclusion (verified):** no shipped product achieves phone-only always-on listening on iOS. All use external hardware or explicit user-started sessions.

## 2. Long-running session limits

- **Screen lock**: recording continues through lock and app-switch when started foreground with `audio` background mode + active session. Keep the session active continuously; deactivating in background forfeits reactivation.
- **Interruptions**: calls/FaceTime/Siri interrupt via `AVAudioSession.interruptionNotification`. After the interruption, a backgrounded app **cannot** reactivate the session (entitlement error) — you cannot silently resume; post a local notification ("tap to resume Saturday") ([thread 813278](https://developer.apple.com/forums/thread/813278)). Biggest UX landmine for ambient sessions.
- **Battery** (order-of-magnitude): mic-only, screen off ≈ **3–5%/hr** (community: ~1% per 15 min, [kentfaith](https://www.kentfaith.com.au/blog/article_how-long-can-iphone-voice-record_615)); ANE-accelerated streaming ASR adds **<4% per hour** on iPhone 15 (WhisperKit measurements, [arXiv 2507.10860](https://arxiv.org/abs/2507.10860)). Realistic combined budget with periodic LLM calls: **~7–12%/hr** *(estimate)*. 2–3 hr sessions fine; all-day is not — again why pendants exist.
- **Memory/thermals**: `SpeechTranscriber` runs out-of-process on the ANE (model not in your memory budget) ([WWDC25 277](https://developer.apple.com/videos/play/wwdc2025/277/)); persist the rolling transcript incrementally in case of jetsam.

## 3. Custom wake word "Hey Saturday"

- **No OS-level always-on wake word for 3rd parties** — the low-power wake-word DSP path is Siri-only; no API to register a system-wide phrase.
- **In-session KWS is feasible** (mic already streaming to the app):
  - **Picovoice Porcupine**: commercial, iOS SDK, custom phrases trainable in minutes; free tier is personal/eval only; paid reportedly from ~**$6k/yr** (100-device tier), custom wake words gated to paid plans; models locked to their SDK ([picovoice.ai](https://picovoice.ai/products/voice/wake-word/), [third-party pricing analysis](https://checkthat.ai/brands/picovoice/pricing) — *pricing is sales-negotiated; treat figures as indicative, unverified with vendor*).
  - **openWakeWord**: open source, custom phrases from synthetic TTS data, ~200KB ONNX models; needs ONNX→Core ML conversion + own audio pipeline ([openwakeword.com](https://openwakeword.com/)). Free; more tuning burden.
  - **DIY Core ML CRNN KWS** template: [OtosakuKWS-iOS](https://github.com/Otosaku/OtosakuKWS-iOS).
  - **Pragmatic alternative**: hotphrase detection on the live ASR transcript ("Saturday…") — zero extra cost, works in Korean.
- **VAD**: Apple **`SpeechDetector`** (new iOS 26 module in the SpeechAnalyzer pipeline, [WWDC25 277](https://developer.apple.com/videos/play/wwdc2025/277/)); **Silero VAD** — MIT, ~1–2MB, <1ms per 30ms chunk on 1 CPU thread, 100+ languages, Core ML port available ([GitHub](https://github.com/snakers4/silero-vad), [CoreML port](https://huggingface.co/FluidInference/silero-vad-coreml)). VAD-gate the ASR to save battery during silence.

## 4. Activation surfaces (fastest intent → live mic)

All surfaces must **launch the app to foreground** to start the mic; one `StartListeningIntent` (`openAppWhenRun = true` / `supportedModes = .foreground`) serves them all ([App Intents guide](https://superwall.com/blog/an-app-intents-field-guide-for-ios-developers)):

- **iPhone Action Button** (15 Pro+): press → app opens → mic live in ~1–2 s. Best surface ([Apple](https://developer.apple.com/documentation/appintents/actionbutton)).
- **Control Center / Lock Screen controls** (iOS 18 `ControlWidget`): button control runs the intent; Lock Screen corner slots supported; launching the app still requires unlock ([WWDC24 10157](https://developer.apple.com/videos/play/wwdc2024/10157/)).
- **Siri**: `AppShortcutsProvider` phrases containing `applicationName` — "Hey Siri, start Saturday." No custom hotword; always rides on Siri ([createwithswift](https://www.createwithswift.com/performing-your-app-actions-with-siri-through-app-shortcuts-provider/)).
- **Widgets + Live Activity**: widget button starts the session; a Dynamic Island Live Activity during recording is both UX and the 2.5.14 "clear visual indication."

## 5. watchOS specifics

- **Mic**: recording works (AVAudioRecorder/AVAudioEngine); must start foreground; watchOS `audio` background mode lets it continue on wrist-down ([Kodeco](https://www.kodeco.com/345-audio-recording-in-watchos-tutorial/page/2)); interrupted recording cannot resume from background ([thread 750432](https://developer.apple.com/forums/thread/750432)).
- **Extended runtime sessions**: type-capped (self-care ~10 min, mindfulness ~1 hr; only physical-therapy and smart-alarm types run in background) ([WWDC19 251](https://asciiwwdc.com/2019/sessions/251)); none legitimately fits ambient listening, and type misuse is a rejection risk. Fake `HKWorkoutSession` is likewise abuse.
- **On-watch ASR**: `SFSpeechRecognizer` **not available on watchOS** ([forum 682508](https://developer.apple.com/forums/thread/682508)); *(unverified but likely: `SpeechAnalyzer` is also absent from watchOS 26 — confirm in Xcode)*. Real transcription must happen on the phone — consistent with Saturday's "phone is the brain" decision. (System *dictation* UI does work on watch and is on-device on S9+ — usable for short queries.)
- **Watch→iPhone streaming** (WatchConnectivity): `sendMessageData` latency ~100ms–1s with queuing/throttling; `isReachable` flaps when the watch app is backgrounded in audio mode ([thread 762327](https://developer.apple.com/forums/thread/762327), [9368](https://developer.apple.com/forums/thread/9368)). Practical pattern: 5–15 s compressed AAC chunks via `sendMessageData`/`transferFile` → phone-side ASR; expect 5–30 s transcript lag *(estimate)*. Truly live low-latency watch-mic streaming is not reliably achievable with public APIs — treat the Watch as trigger + short-query surface, iPhone as the session recorder.
- **Watch activation**: complication / Smart Stack widget → app opens → record. Ultra **Action button**: 3rd-party support only via workout/dive intents or a user-assigned Shortcut ([Apple](https://developer.apple.com/documentation/appintents/actionbuttonarticle)) — Shortcut route works. **Double Tap: no 3rd-party API** (notifications/primary-button only, [MacRumors](https://www.macrumors.com/2023/10/25/watchos-10-1-double-tap-gesture/)). **Raise-to-speak is Siri-only** — reachable indirectly via "…ask Saturday…" phrases.

## 6. Legal / privacy

- **Korea (통신비밀보호법)**: recording a conversation **you participate in** is legal, even covertly — not "타인 간의 대화" ([Yulchon](https://www.yulchon.com/ko/resources/publications/legal-update-view/36516/page.do), [법무법인 법승](https://www.lawwin.co.kr/incheon/knowledgedetail?index=7039)). Recording conversations **between others** (non-participant) is criminal — 1–10 yrs imprisonment; Supreme Court precedent: one participant's consent does not legalize a non-participant's recording ([뉴로이어](https://www.newlawyer.co.kr/41/241)). Saturday is fine while the user is a participant; nearby-stranger capture is not. PIPA (개인정보보호법) treats voice as personal data — transcribe-and-discard-audio, fully on-device, is the strongest mitigation.
- **US**: 12 states + DC are all-party consent: CA, CT, DE, FL, IL, MD, MA, MI, MT, NV, NH, PA, WA ([recordinglaw.com](https://www.recordinglaw.com/party-two-party-consent-states/)); others one-party. Shipped products put consent burden on the wearer/user; Saturday should do the same in onboarding copy.
- **App Store privacy machinery**: nutrition label must declare **"Audio Data — the user's voice or sound recordings"** ([Apple privacy details](https://developer.apple.com/app-store/app-privacy-details/)); privacy manifest + specific purpose string; 5.1.2's third-party-AI clause is moot for a no-cloud app — "audio never leaves the device, discarded after transcription" is simultaneously the best review-risk reducer, legal mitigation, and the marketing position.

## Design implications for Saturday

1. iPhone owns the session: explicit start → foreground mic → `audio` background mode keeps it alive after lock; Live Activity shows "listening."
2. Rolling transcript via `SpeechAnalyzer`/`SpeechTranscriber` *(verify ko-KR locale availability on-device — unverified)*; WhisperKit fallback.
3. "Hey Saturday" = in-session KWS (openWakeWord/DIY Core ML; Porcupine only if licensing budget exists) or transcript hotphrase — never system-wide.
4. Handle interruption → cannot-resume with an immediate "tap to resume" local notification (design this into M0).
5. Watch = trigger + Q&A surface over WatchConnectivity chunked audio; iPhone is the recorder. No Double Tap API; Ultra Action button via Shortcuts only.
6. App Store framing: user-initiated conversation note-taker with visible recording state and consent guidance; audio-discard by default.
