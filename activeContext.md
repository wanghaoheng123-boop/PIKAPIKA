# Active context — volatile handoff state

**Last updated:** 2026-04-18

## Product milestone

**[Docs/ROADMAP.md](Docs/ROADMAP.md):** P0 scaffold complete. **Active engineering target: P1 — AI chat MVP.**

## Canonical app targets (edit these for new UI/features)

- **[Apps/iOS](Apps/iOS)** — XcodeGen (`project.yml`); run **`Scripts/generate-xcode.sh`**, open **`Apps/iOS/Pika.xcodeproj`**.
- **[Apps/macOS](Apps/macOS)** — same flow → **`Apps/macOS/Pika.xcodeproj`**.

SwiftData `ModelContainer` is declared in [Apps/iOS/Sources/PikaApp.swift](Apps/iOS/Sources/PikaApp.swift) / [Apps/macOS/Sources/PikaApp.swift](Apps/macOS/Sources/PikaApp.swift) for `Pet`, `BondEvent`, `ConversationMessage`, `SeasonalEvent`.

## Reference-only (do not treat as default edit surface)

- **[Apps/PIKAPIKA](Apps/PIKAPIKA)** — older iOS tree with committed **`PIKAPIKA.xcodeproj`**. Contains **SwiftData-backed** [ChatView](Apps/PIKAPIKA/PIKAPIKA/ChatView.swift) and [PetChatActions](Apps/PIKAPIKA/PIKAPIKA/PetChatActions.swift) (trim-to-50, inserts). Use as implementation reference when porting behavior to iOS/macOS Pika apps.

## P1 — next implementation slice (see Cursor plan / ROADMAP)

1. Replace in-memory chat in [Apps/iOS/Sources/ChatView.swift](Apps/iOS/Sources/ChatView.swift) and [Apps/macOS/Sources/ChatView.swift](Apps/macOS/Sources/ChatView.swift) with `@Query` + `ConversationMessage` persistence (align with architecture + PIKAPIKA reference).
2. Prune to last 50 messages per pet; router fallback on 5xx / rate-limit; Settings provider + test connection; ChatView retry UX.

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
