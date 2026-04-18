# Active context — volatile handoff state

**Last updated:** 2026-04-18

## Product milestone

**[Docs/ROADMAP.md](Docs/ROADMAP.md):** P0 scaffold complete; **P1 — AI chat MVP** shipped (2026-04-18). **Active engineering target: P2 — Bond loop.**

## Canonical app targets (edit these for new UI/features)

- **[Apps/iOS](Apps/iOS)** — XcodeGen (`project.yml`); run **`Scripts/generate-xcode.sh`**, open **`Apps/iOS/Pika.xcodeproj`**.
- **[Apps/macOS](Apps/macOS)** — same flow → **`Apps/macOS/Pika.xcodeproj`**.

SwiftData `ModelContainer` is declared in [Apps/iOS/Sources/PikaApp.swift](Apps/iOS/Sources/PikaApp.swift) / [Apps/macOS/Sources/PikaApp.swift](Apps/macOS/Sources/PikaApp.swift) for `Pet`, `BondEvent`, `ConversationMessage`, `SeasonalEvent`.

## Reference-only (do not treat as default edit surface)

- **[Apps/PIKAPIKA](Apps/PIKAPIKA)** — older iOS tree with committed **`PIKAPIKA.xcodeproj`**. Contains **SwiftData-backed** [ChatView](Apps/PIKAPIKA/PIKAPIKA/ChatView.swift) and [PetChatActions](Apps/PIKAPIKA/PIKAPIKA/PetChatActions.swift) (trim-to-50, inserts). Use as implementation reference when porting behavior to iOS/macOS Pika apps.

## P2 — next implementation slice

- Daily streak, bond XP UI polish, `BondProgression.dailyCap` at call sites, `BondEvent` surfacing — see [Docs/ROADMAP.md](Docs/ROADMAP.md).

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

- None recorded.
