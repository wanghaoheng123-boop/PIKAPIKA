# Architecture

## Package graph

```
Apps/iOS + Apps/macOS
        │
        ▼
  ┌───────────────────────────────────────────────┐
  │ SharedUI  PikaSubscription  PikaSync  PetEngine  PikaAI │
  └───────────────────────────────────────────────┘
                         │
                         ▼
                     PikaCore
```

`PikaCore` is the stable API surface. Every other package depends on it and
nothing else (except Apple frameworks). This keeps the dependency graph a tree
and allows unit tests to avoid pulling in AppKit/UIKit where possible.

## Application targets (two trees)

| Location | Xcode project | Purpose |
|----------|----------------|---------|
| **`Apps/iOS`**, **`Apps/macOS`** | Generated **`Pika.xcodeproj`** via **`Scripts/generate-xcode.sh`** | **Canonical** SwiftUI apps for ongoing work ([`project.yml`](Apps/iOS/project.yml)). Consume packages above; `ChatView` here currently keeps chat **in RAM** until [ROADMAP](ROADMAP.md) P1 persists `ConversationMessage`. |
| **`Apps/PIKAPIKA`** | Committed **`PIKAPIKA.xcodeproj`** | **Reference** iOS app: SwiftData-backed chat, `PetChatActions`, voice, and other patterns to port or compare — not the default target for new milestones unless specified. |

Agents should read **[`activeContext.md`](../activeContext.md)** and **[`Docs/ROADMAP.md`](ROADMAP.md)** before choosing edit paths.

## Data flow — "pet reacts to user"

```
[ActivityMonitor] ──UserActivity──▶ [PetBehaviorEngine] ──PetState──▶ [AnimationDirector]
                                                  │
                                                  └── awards XP via [BondProgression]
                                                                        │
                                                                        ▼
                                                                  [SwiftData]
                                                                        │
                                                                        ▼
                                                           [PikaSync → CloudKit]
```

## Data flow — "chat turn"

```
User types ─▶ ChatView ─▶ AIProviderRouter ─▶ AnthropicClient (with prompt cache)
                                            └─▶ OpenAIClient   (fallback)
                                                       │
                                                       ▼
                                             AsyncThrowingStream<String>
                                                       │
                                                       ▼
                                               ChatBubble renders tokens
                                                       │
                                                       ▼
                                             BondProgression.chatMessage
```

## Concurrency

- All packages compile with `SWIFT_STRICT_CONCURRENCY=complete`.
- `PetBehaviorEngine` is an actor — transitions are serialized.
- `SubscriptionManager` is `@MainActor` because it updates `@Published` state
  that drives SwiftUI.
- `KeychainHelper` is a pure namespace of static functions; safe from any
  thread.

## Persistence

- SwiftData is the single local store. Models: `Pet`, `BondEvent`,
  `ConversationMessage`, `SeasonalEvent`.
- CloudKit sync rides SwiftData's automatic integration for `Pet`; custom
  record types use `PikaSync.CloudKitSyncCoordinator`.
- Only the last 50 `ConversationMessage` rows per pet are retained; older
  rows get purged by a background task (TODO: implement in P1).

## AI integration

- Default provider: Anthropic (`claude-sonnet-4-6`) with prompt caching on
  the system prompt, since personality + bond + context change slowly per
  pet. See `Docs/AI_INTEGRATION.md`.
- Image generation falls back to OpenAI `dall-e-3` regardless of chat
  preference (Anthropic has no native image generation).
