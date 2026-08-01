# Research: On-Device LLM/ASR Feasibility (iPhone + Apple Watch)

*Research snapshot: August 2026. iOS 26 is the current shipping OS; iOS 27 / watchOS 27 were announced at WWDC 2026 and are in beta (fall 2026 release). Items not confirmed against a primary source are marked **[unverified]**.*

## 1. Apple Foundation Models Framework (iOS 26+)

**What it is.** A native Swift API (`FoundationModels`) giving 3rd-party apps direct access to the same ~3B-parameter on-device LLM that powers Apple Intelligence. Runs entirely on-device (CPU/GPU/ANE), works offline, **zero cost, no API keys, no per-token billing** — it fully satisfies the "no cloud LLM API" constraint. ([Apple Newsroom](https://www.apple.com/newsroom/2025/09/apples-foundation-models-framework-unlocks-new-intelligent-app-experiences/), [Apple ML Research](https://machinelearning.apple.com/research/apple-foundation-models-2025-updates))

**Model & capabilities**
- ~3B parameters, aggressively quantized (~2 bits/weight per Apple's tech report), so its RAM/disk cost to the app is effectively zero — the OS owns and serves the model. ([Apple Intelligence Foundation Language Models Tech Report 2025](https://arxiv.org/pdf/2507.13575))
- Designed for: summarization, entity extraction, text understanding/refinement, **short dialog**, creative generation. Explicitly **not** a general-world-knowledge chatbot. ([Apple ML Research](https://machinelearning.apple.com/research/apple-foundation-models-2025-updates))
- **Guided generation**: `@Generable` macro constrains decoding to typed Swift structs/enums — guaranteed-valid structured output. **Tool calling**: framework guarantees structurally correct tool calls (no hallucinated tool names/args) and handles parallel/serial call graphs — ideal for Saturday's EventKit/MKLocalSearch actions. ([WWDC25 session 286](https://developer.apple.com/videos/play/wwdc2025/286/), [createwithswift.com](https://www.createwithswift.com/exploring-the-foundation-models-framework/))
- **Adapters**: Python/PyTorch Adapter Training Toolkit; LoRA rank-32, ~160 MB per adapter, delivered via Background Assets, ships only with the `com.apple.developer.foundation-model-adapter` entitlement. Caveat: adapters are tied to a base-model version and must be retrained when Apple updates the OS model. ([Apple docs](https://developer.apple.com/documentation/foundationmodels/loading-and-using-a-custom-adapter-with-foundation-models), [datawizz.ai](https://datawizz.ai/blog/apple-foundation-models-framework-benchmarks-and-custom-adapters-training-with-datawizz))

**Korean: yes.** Apple Intelligence supports Korean (added iOS 18.4), and Foundation Models supports all Apple Intelligence languages — ~16 languages / 23 locales including `ko` alongside English. ([Apple docs — languages/locales](https://developer.apple.com/documentation/foundationmodels/supporting-languages-and-locales-with-foundation-models), [rudrank.com](https://rudrank.com/exploring-foundation-models-supported-languages-internationalization)) Korean answer *quality* vs English on the 3B model: **[unverified — no public benchmark found; test in beta]**.

**Hard constraints**

| Constraint | Value | Source |
|---|---|---|
| Context window | **4,096 tokens fixed** per `LanguageModelSession` (input + output combined); throws `.exceededContextWindowSize` | [Apple TN3193](https://developer.apple.com/documentation/technotes/tn3193-managing-the-on-device-foundation-model-s-context-window), [forums](https://developer.apple.com/forums/thread/806542) |
| Devices | Apple Intelligence hardware only: iPhone 15 Pro/Pro Max and all iPhone 16/17 (A17 Pro+, 8 GB RAM), iOS 26+, Apple Intelligence enabled + model downloaded | [Apple support](https://support.apple.com/en-gb/guide/iphone/aside/iph275f4d617/26/ios/26) |
| Rate limits | Foreground use effectively unthrottled; throttling applies **on battery + running in background** (relevant to app extensions / background sessions) | [Apple forums](https://developer.apple.com/forums/thread/789788) |
| Availability | Must check `SystemLanguageModel.default.availability` and handle `.unavailable` cases | [fallback guide](https://dev.to/arshtechpro/how-to-fall-back-gracefully-when-apple-intelligence-isnt-available-48j) |

**Limitations for Saturday**: 4k context forces transcript compaction; weak world knowledge; guardrails can refuse benign prompts; model behavior shifts with OS updates (re-test each iOS release); unavailable on non-Pro iPhone 15 and older.

**iOS 27 (WWDC26, beta now)**: rebuilt on-device model ("better at logic and tool calling"), **multimodal image prompts**, a public `LanguageModel` protocol so the framework can front *any* model (Apple's, a bundled open model, or cloud providers), and per-response token-usage reporting. ([What's new in Foundation Models — WWDC26](https://developer.apple.com/videos/play/wwdc2026/241/), [Bring an LLM provider to Foundation Models — WWDC26](https://developer.apple.com/videos/play/wwdc2026/339/))

## 2. Bundling an Open-Source Model

### Runtime benchmarks (iPhone 17 Pro / A19 Pro, 2B-class model, 4-bit, short-chat decode)
From the neutral open benchmark [john-rocky/apple-silicon-llm-bench](https://github.com/john-rocky/apple-silicon-llm-bench); an independent test on Qwen-2B-class measured MLX-Swift 61 tok/s vs llama.cpp 39.1 vs Core ML/ANE 27.9 ([MLBoy, Medium](https://rockyshikoku.medium.com/local-llm-on-iphone-which-runtime-is-actually-fastest-58096685481e)).

| Runtime | Decode tok/s | Peak RAM | Sustained 10 min | Notes |
|---|---|---|---|---|
| **LiteRT-LM** (GPU) | **52.7** | **487 MB** (QAT) | 27 tok/s (48% retention) | Fastest and smallest loadable footprint; best Gemma path |
| Cactus | 50.6 | 1,061 MB | — | |
| **MLX-Swift** (GPU) | 46.4 | 3,010 MB | 18 tok/s (38%) | Easiest from Swift; widest model zoo (Qwen etc.) |
| **llama.cpp** (GGUF) | 37.6 | **253 MB** wired (mmap) | — | Lowest memory; runs any GGUF |
| Core ML / ANE | 34.2 | 553 MB | **22 tok/s (67% retention)** | Best thermal retention; frees GPU for UI; conversion painful |

**Thermal/battery reality**: GPU runtimes lose ~50–60% throughput after ~10 min sustained; ANE retains ~65%. Sustained decode costs roughly **1% battery/min**; a measured iPhone 16 Pro run degraded 40.4 → 22.6 tok/s (−44%) within two iterations, with ~5–10% battery per 20 inferences. Energy varies 4× by runtime on the same phone (0.11 J/tok Apple FM vs 0.48 J/tok Core ML config on M-class test). Design for **short answer bursts**, never continuous generation. ([arXiv 2603.23640](https://arxiv.org/html/2603.23640v2), [On-Device LLMs: State of the Union 2026](https://v-chandra.github.io/on-device-llms/), bench repo)

**Memory ceiling (jetsam)**: ~**4 GB** per app on 8 GB iPhones (15 Pro → 17) before jetsam kill; the **Increased Memory Limit** entitlement raises it somewhat, never past physical RAM; ~3 GB on 6 GB devices. Practical rule: **4-bit ≤4B params is safe; 7–8B is marginal and not recommended.** ([entitlements writeup](https://zenn.dev/mtfum/articles/ios_memory_entitlements?locale=en), [iOS memory-limit table](https://github.com/PojavLauncherTeam/PojavLauncher_iOS/issues/97))

### Model candidates (Korean + English, 1–8B)

| Model | Params | 4-bit weights | Korean | License | Verdict |
|---|---|---|---|---|---|
| **Qwen3 1.7B / 4B** | 1.7B / 4B | ~1.0 / ~2.3 GB | Good (119 languages, strong CJK) | **Apache 2.0** | Best license + MLX support; 4B is the sweet spot ([Qwen3 blog](https://qwenlm.github.io/blog/qwen3/)) |
| **HyperCLOVA X SEED 0.5B/1.5B/3B** (NAVER) | 0.5–3B | ~0.4–1.8 GB | **Excellent, Korean-first** | Free commercial use **< 10M MAU** | Best Korean-native option that is legally shippable ([HF collection](https://huggingface.co/collections/naver-hyperclovax/hyperclova-x-seed), [Korea Times](https://www.koreatimes.co.kr/business/companies/20250423/naver-to-release-3-ai-models-as-open-source-free-for-commercial-use)) |
| Gemma 3n E2B/E4B (and 2026 edge successors) | 5B/8B raw → 2B/4B effective | runs in ~2 / ~3 GB (PLE mem-mapped; text-only weights as low as 0.8 GB on LiteRT-LM) | Good (35+ languages) | Gemma terms (commercial OK) | Best on LiteRT-LM; native audio/image input ([Google dev blog](https://developers.googleblog.com/en/introducing-gemma-3n-developer-guide/), [LiteRT-LM](https://developers.googleblog.com/blazing-fast-on-device-genai-with-litert-lm/)) |
| EXAONE 3.5 2.4B / 4.0 1.2B (LG) | 1.2–2.4B | ~0.8–1.5 GB | **Excellent** | **Non-commercial only**; commercial use needs an LG agreement | Blocked for a paid app unless licensed ([license](https://github.com/LG-AI-EXAONE/EXAONE-3.0/blob/main/LICENSE)) |
| Kanana Nano 2.1B (Kakao) | 2.1B | ~1.3 GB | Excellent | **CC-BY-NC-4.0** | Blocked for a paid app ([HF card](https://huggingface.co/kakaocorp/kanana-nano-2.1b-instruct)) |
| Llama 3.2 3B | 3B | ~1.9 GB | **Not officially supported**; community fine-tunes exist ([Bllossom 3B](https://huggingface.co/Bllossom/llama-3.2-Korean-Bllossom-3B)) | Llama Community | Skip — Korean is the weak point ([NVIDIA docs](https://docs.nvidia.com/nim/vision-language-models/1.2.0/examples/llama3-2/overview.html)) |
| Phi-4-mini | 3.8B | ~2.3 GB | Listed, mid-tier | MIT | Backup ([HF card](https://huggingface.co/microsoft/Phi-4-mini-instruct)) |

Decode on A17 Pro/A18 (target fallback hardware): **[estimate, unverified]** ~30–45 tok/s for 2B-class and ~15–25 tok/s for 4B-class 4-bit via MLX, scaling down from A19 Pro numbers. Ship no weights in the binary; download post-install via Background Assets / On-Demand Resources (1–2.5 GB).

## 3. Apple Watch Feasibility

**Verdict: no meaningful LLM can run on any current Apple Watch. The Watch must be a thin client — which matches Saturday's decided architecture.**

- S9/S10 (and S11-class) have a 4-core Neural Engine but only **1 GB RAM**, 64 GB storage. ([Apple Newsroom S9](https://www.apple.com/newsroom/2023/09/apple-introduces-the-advanced-new-apple-watch-series-9/), [Series 10 specs](https://ofzenandcomputing.com/apple-watch-series-10-specifications/))
- watchOS per-app memory limits are undocumented and tiny — system processes have been observed with ~35 MB jetsam limits; third-party budgets are empirically in the tens of MB **[exact figure unverified — Apple does not publish it]**. Even a 0.5B model at 4-bit needs ~400 MB resident: an order of magnitude over budget. ([jetsam docs](https://developer.apple.com/documentation/xcode/identifying-high-memory-use-with-jetsam-event-reports), [fatbobman watchOS pitfalls](https://fatbobman.com/en/posts/watchos-development-pitfalls-and-practical-tips))
- Apple's own design confirms the thin-client model: **watchOS 27's new Siri AI requires a nearby Apple-Intelligence iPhone** (phone does the LLM work). `FoundationModels` appears in watchOS 27 betas via the `LanguageModel` protocol, but that is a provider interface — no evidence the 3B model executes on watch silicon **[on-watch execution: unverified/doubtful]**. ([TechRadar interview with Apple watchOS team](https://www.techradar.com/health-fitness/smartwatches/its-the-most-convenient-way-to-interact-with-siri-i-asked-apples-senior-watchos-team-how-to-use-the-new-siri-ai-assistant-on-an-apple-watch-and-why-its-not-coming-to-so-many-older-models), [AppleInsider](https://appleinsider.com/articles/26/06/19/siri-ai-leaves-older-apple-watches-behind-without-a-clear-reason))
- **SpeechTranscriber (new STT) is available on all platforms except watchOS.** ([Appcircle WWDC25 writeup](https://appcircle.io/blog/wwdc25-bring-advanced-speech-to-text-capabilities-to-your-app-with-speechanalyzer))

**WatchConnectivity channel**: `sendMessage` round-trips of ~0.1–1 s reported (0.8 s measured in forum threads); payload cap ~65 KB per message **[cap figure: unverified against current docs]**; reachability degrades when the watch app is backgrounded in audio mode, and the phone app must be at least backgrounded. Practical patterns: (a) run **system dictation on-watch** (on-device on S9+) and send text — small, fast, robust; or (b) chunk compressed audio (16 kHz Opus/AAC) via `sendMessageData` for phone-side SpeechTranscriber — higher fidelity, more fragile. Prototype (b) early; it is Saturday's risk #2. ([latency thread](https://developer.apple.com/forums/thread/9368), [audio-background thread](https://developer.apple.com/forums/thread/762327))

## 4. On-Device Speech I/O

**STT**
- **SpeechAnalyzer / SpeechTranscriber (iOS 26+)** — the clear primary choice. Fully on-device, system-managed models (zero app-size cost, shared across apps via `AssetInventory`), streaming volatile+finalized results, and reported ~2× faster than Whisper large-v3-turbo. **`ko_KR` is in `SpeechTranscriber.supportedLocales`** (42 locales as of mid-2026). Includes `SpeechDetector` (VAD). Not on watchOS. ([WWDC25 session 277](https://developer.apple.com/videos/play/wwdc2025/277/), [Argmax × Apple](https://www.argmaxinc.com/blog/apple-and-argmax), [locale list, Jul 2026](https://medium.com/@itsuki.enjoy/swift-speechtranscriber-support-multi-language-without-manual-locale-switching-b626b547bd74)) Korean WER vs English: **[unverified — no published per-language numbers]**.
- **SFSpeechRecognizer (legacy, iOS < 26 fallback)**: `ko-KR` supported; on-device mode availability for Korean varies by device/OS — check `supportsOnDeviceRecognition` at runtime **[Korean on-device coverage: unverified]**. ([Apple docs](https://developer.apple.com/documentation/Speech/SFSpeechRecognizer/supportsOnDeviceRecognition))
- **WhisperKit (Argmax)**: 0.46 s streaming latency at 2.2% WER (English); large-v3-turbo is 809M params (~0.6–1 GB in RAM quantized). Bundle only if supporting pre-iOS-26 devices; small Whisper variants degrade on Korean. ([WhisperKit paper](https://arxiv.org/abs/2507.10860), [benchmarks](https://github.com/argmaxinc/argmax-oss-swift/discussions/243))

**TTS**
- **AVSpeechSynthesizer**: free, on-device, Korean voices (Yuna; standard + enhanced tiers). Serviceable but below modern neural quality; Siri's voice is not exposed to apps. ([Apple docs](https://developer.apple.com/documentation/avfaudio/avspeechsynthesisvoice), [device voice list](https://gist.github.com/Koze/d1de49c24fc28375a9e314c72f7fdae4))
- **Kokoro-82M**: open neural TTS, ~80 MB INT8, multilingual incl. Korean; Swift/MLX and Core ML ports run ~3.3× real-time on iPhone 13 Pro. Korean voice quality of the iOS ports: **[unverified — needs listening tests]**. ([kokoro-swift-mlx](https://github.com/mattmireles/kokoro-swift-mlx), [mlx-audio](https://github.com/Blaizzy/mlx-audio), [voice guide](https://soniqo.audio/guides/kokoro))
- Personal Voice is accessibility-oriented; Korean support and 3rd-party use are limited **[unverified]** — not a fit.

## 5. Summary Table & Recommendation

| Component | Peak RAM (app) | Speed | Korean | Cost/License |
|---|---|---|---|---|
| Apple Foundation Models (~3B, system) | ~0 | fast; most energy-efficient measured (0.11 J/tok) | Yes | Free, no API |
| Qwen3-4B @ MLX | ~2.8–3 GB | ~15–25 tok/s A17 Pro/A18 (est.) | Good | Apache 2.0 |
| Qwen3-1.7B @ MLX | ~1.5 GB | ~40–60 tok/s | OK | Apache 2.0 |
| HyperCLOVA X SEED 1.5B/3B | ~1–2 GB | similar tier | Excellent | Free < 10M MAU |
| Gemma 3n/4 E2B @ LiteRT-LM | ~0.5–2 GB | 52.7 tok/s (A19 Pro); best sustained-per-MB | Good | Gemma terms |
| SpeechTranscriber (system) | ~0 | streaming; ~2× Whisper-turbo | Yes (`ko_KR`) | Free |
| WhisperKit turbo (fallback STT) | ~0.6–1 GB | 0.46 s latency | Good | MIT |
| Kokoro TTS | ~0.1–0.3 GB | 3.3× real-time | Yes (quality TBD) | Apache 2.0 |
| AVSpeechSynthesizer | ~0 | instant | Yes | Free |

**Recommended architecture**

- **Tier 1 (primary — Apple Intelligence iPhones: 15 Pro+, all 16/17):** SpeechTranscriber (`ko_KR`/`en_US`) → **Foundation Models** with `@Generable` guided generation + `Tool` calling (EventKit, MKLocalSearch, message drafts) → AVSpeechSynthesizer (Kokoro as quality upgrade). All free, on-device, ~0 app RAM. Handle the 4,096-token window with a **rolling transcript buffer**: last N turns verbatim + LLM-generated summary of older content; rebuild the session with condensed history on `.exceededContextWindowSize` (Apple's documented TN3193 pattern).
- **Tier 2 (fallback — non-Apple-Intelligence devices):** downloadable **Qwen3-4B 4-bit** (8 GB devices) or **Qwen3-1.7B / HyperCLOVA X SEED 1.5B** (6 GB devices) via MLX-Swift (or LiteRT-LM for best sustained throughput per MB); WhisperKit or on-device SFSpeechRecognizer for STT. Avoid EXAONE/Kanana in a paid app without a license deal despite superior Korean.
- **Watch = thin client:** on-watch dictation → text over WatchConnectivity (primary), chunked audio streaming as the higher-fidelity experiment; phone does STT + LLM + TTS and streams reply text back. Re-evaluate when watchOS 27 ships (its `LanguageModel` protocol + phone-proxied Siri AI may yield a sanctioned offload path).
- **When iOS 27 lands:** put Tier 1 and Tier 2 behind the new `LanguageModel` protocol — Apple's now-official hybrid pattern.

**Key risks:** 4k context (compaction required); thermal/battery under long sessions (~1%/min sustained decode, 40–60% GPU throttle after 10 min — answer in short bursts, prefer ANE/LiteRT for sustained work); Foundation Models guardrail refusals and per-OS-release model drift; Korean TTS quality gap; Tier-2 fallback roughly doubles engineering surface.
