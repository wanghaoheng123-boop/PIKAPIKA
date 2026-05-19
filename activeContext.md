# Active context — volatile handoff state

**Last updated:** 2026-05-03

## Product milestone

**[Docs/ROADMAP.md](Docs/ROADMAP.md):** P0 scaffold complete; **P1 — AI chat MVP** shipped (2026-04-18). **Active engineering target: P2 — Bond loop.**

## Scope lock (2026-04-27)

- **Confirmed scope:** this execution run is **PIKAPIKA-only** (pet companion app), not a separate trading/QuantLab product.
- **Interpretation for “analysis/backtesting”:**
  - Backtesting = deterministic, repeatable tests/simulations over PIKAPIKA algorithms (`BondProgression`, `PetInteractionStreak`, AI routing/memory extraction).
  - Competitive research (Moomoo/Panda/GitHub) is used only for transferable UX/process patterns, not direct broker/trading feature cloning.
- **Future option:** if QuantLab/trading is required later, open a dedicated repo/module and reuse the same quality loop process.
- **Execution artifacts (2026-04-27):**
  - `workspace/competitive-research-notes.md`
  - `workspace/mcp-review-pass-2026-04-27.md`
  - `workspace/xcodeproj-repair-2026-04-27.md`
  - `workspace/feedback-prioritization-loop.md`

## Canonical app targets (edit these for new UI/features)

- **[Apps/iOS](Apps/iOS)** — XcodeGen (`project.yml`); run **`Scripts/generate-xcode.sh`**, open **`Apps/iOS/Pika.xcodeproj`**.
- **[Apps/macOS](Apps/macOS)** — same flow → **`Apps/macOS/Pika.xcodeproj`**.

SwiftData `ModelContainer` is declared in [Apps/iOS/Sources/PikaApp.swift](Apps/iOS/Sources/PikaApp.swift) / [Apps/macOS/Sources/PikaApp.swift](Apps/macOS/Sources/PikaApp.swift) for `Pet`, `BondEvent`, `ConversationMessage`, `SeasonalEvent`.

## Reference-only (do not treat as default edit surface)

- **[Apps/PIKAPIKA](Apps/PIKAPIKA)** — older iOS tree with committed **`PIKAPIKA.xcodeproj`**. Contains **SwiftData-backed** [ChatView](Apps/PIKAPIKA/PIKAPIKA/ChatView.swift) and [PetChatActions](Apps/PIKAPIKA/PIKAPIKA/PetChatActions.swift) (trim-to-50, inserts). Use as implementation reference when porting behavior to iOS/macOS Pika apps.

## P2 — next implementation slice

- Daily streak, bond XP UI polish, `BondProgression.dailyCap` at call sites, `BondEvent` surfacing — see [Docs/ROADMAP.md](Docs/ROADMAP.md).
- Implemented in current slice:
  - Shared award helper: `PetInteractionStreak.applyBondEvent(...)` in [Packages/PikaCore/Sources/PikaCorePersistence/PetInteractionStreak.swift](Packages/PikaCore/Sources/PikaCorePersistence/PetInteractionStreak.swift)
  - iOS/macOS home views now consume shared cap/event flow and show daily XP/event UI.
  - Shared chat writes `.chatMessage` bond events and surfaces daily bond status.
  - Level-up toast/banner feedback added in iOS/macOS home + shared chat.
  - Additional optimization pass: smoother `TypingIndicator` animation and tighter SSE line parsing in `OpenAIClient`, `DeepSeekClient`, and `AnthropicClient`.
  - Enterprise readiness hardening pass: provider network/session policy, error sanitization, privacy toggle for memory mirror, file protection on exported memory/image files, app + shared test foundations, and CI security/release gates.

## P1 (done) — pointers

- Shared chat + settings: [Apps/Shared/Sources](Apps/Shared/Sources) (`PetChatScreen`, `PikaSettingsContent`, `ConversationHistoryLimits`).
- Router fallback + tests: [Packages/PikaAI/Sources/PikaAI/AIProviderRouter.swift](Packages/PikaAI/Sources/PikaAI/AIProviderRouter.swift), [Packages/PikaAI/Tests/PikaAITests/AIProviderRouterTests.swift](Packages/PikaAI/Tests/PikaAITests/AIProviderRouterTests.swift).
- Thin app shells: [Apps/iOS/Sources/ChatView.swift](Apps/iOS/Sources/ChatView.swift), [Apps/macOS/Sources/ChatView.swift](Apps/macOS/Sources/ChatView.swift).

## Handoff protocol (template)

```text
Delegation ID: <short-id>
Date/UTC: <optional>
Agent: <e.g. explore / debugger / test-runner>
Mandate: <one paragraph>
Expected output: <dense summary + file paths>
Resume: <what the next agent should do if interrupted>
```

## Blockers

- Local `swift` CLI unavailable in this Windows session; package tests/type-check must be run on macOS/Xcode toolchain.
- Enterprise release gate requires configured `DEVELOPMENT_TEAM` and non-bootstrap marketing/build versions before release policy check can pass.
