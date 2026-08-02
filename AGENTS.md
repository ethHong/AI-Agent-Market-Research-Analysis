# AGENTS.md — Saturday (guidance for Codex and other coding agents)

This repo is co-developed by multiple AI agents (Claude Code, Codex) and the owner
(Ethan). Read this first; then read `CLAUDE.md` (same rules apply to you, despite the
filename) and `HANDOFF.md` (current baton state).

## The 60-second brief

Saturday = paid iPhone + Apple Watch assistant that listens *with* you during a
conversation (explicit session, never always-on) and answers mid-conversation
questions using the transcript as context. 100% on-device ASR + LLM (Apple
Foundation Models primary, MLX Qwen3 fallback); no cloud LLM APIs, no servers, no
subscription. English first, Korean fast-follow. Full product/tech docs in
`docs/saturday/00–06` — decisions there are settled; don't re-litigate them in code.

## Hard rules

1. **Never break the layer split** (see `app/README.md`): `app/SaturdayCore` stays
   free of UIKit/SwiftUI/AVFoundation/FoundationModels imports so it builds and
   tests on Linux. Platform code lives in `app/SaturdayApp` / `app/SaturdayWatch`.
2. **Run core tests before pushing** anything that touches `SaturdayCore`:
   `cd app/SaturdayCore && swift test` — keep it at zero failures.
3. **`⚠️ UNVERIFIED-ON-DEVICE` headers** mark files never compiled in Xcode. If you
   verify one on a Mac, delete the header and log it in `HANDOFF.md`. If you edit
   one off-Mac, leave the header in place.
4. **Privacy invariants are product law**: no transcript text in any network
   request (web lookup sends LLM-composed query terms only); no cloud inference;
   no background-start recording; no always-on listening. If a change would bend
   one of these, stop and raise it in `HANDOFF.md` instead.
5. Don't touch `README.md` (legacy market research) or `Research - Slides/`.
6. Branch: work lands on `claude/saturday-ai-assistant-app-bfbo3x` (or a branch
   the owner names). Clear commit messages; no force-push over others' work.

## Handoff protocol (agent ↔ agent ↔ owner)

- `HANDOFF.md` at repo root is the single running baton. Before starting: read the
  top entry. After finishing: prepend a new entry (newest first) with the template
  in that file — what you did, what's verified vs not, what's next, landmines.
- Keep entries honest about verification status ("wrote X" ≠ "X works"). The
  Linux-side agents cannot compile iOS code; Mac-side sessions must close that gap
  and say so in their entry.
- Open questions for the owner go in the entry's "Needs owner input" line — don't
  silently decide product questions (pricing, scope, privacy posture).

## Where things are

```
docs/saturday/          product brief, research (LLM/audio/integrations), architecture,
                        roadmap (M0 spikes first!), features/differentiation
app/SaturdayCore/       tested pure-Swift brain (see app/README.md)
app/SaturdayApp/        iOS shell (SwiftUI, audio, ASR, AFM backend, tools)
app/SaturdayWatch/      watchOS thin client (dictation → WatchConnectivity)
app/project.yml         XcodeGen spec — `xcodegen generate` on Mac
HANDOFF.md              running baton log
```
