# System patterns — PIKAPIKA

## Phase 1 meta-architecture decision (baseline retained)

**Decision:** Keep the **baseline Memory Bank** layout (`projectbrief`, `productContext`, `systemPatterns`, `techContext`, `progress`, `activeContext`, `AGENTS`).

**Rationale:** Community and handbook guidance (e.g. structured markdown for agent continuity—see Tweag *Agentic Coding Handbook* memory bank patterns) converges on a small set of human-editable files. Adding a custom finite-state machine spec or extra topology files is **not** justified until this repo grows multiple app targets or multi-package workflows that require explicit state charts.

**Revisit when:** Multiple long-running feature epics need parallel agent lanes with explicit gates; then consider a lightweight `state/` or `workflows/` folder with machine-readable definitions.

## Repository layout

```
PIKAPIKA/
├── Apps/
│   ├── iOS/                    # XcodeGen → `Pika.xcodeproj` (see Scripts/generate-xcode.sh)
│   ├── macOS/                  # XcodeGen → `Pika.xcodeproj`
│   └── PIKAPIKA/               # Legacy iOS app: committed `PIKAPIKA.xcodeproj`; richer UI + SwiftData chat reference
├── Backend/                    # Firebase functions, rules, schema docs
├── Docs/                       # ROADMAP, ARCHITECTURE, AI_INTEGRATION, …
├── Packages/
│   ├── PikaCoreBase/           # Domain + protocols; CLI-safe `swift test`
│   ├── PikaCore/               # SwiftData `@Model` + umbrella `PikaCore`
│   ├── PikaAI/
│   ├── PetEngine/
│   ├── PikaSync/
│   ├── PikaSubscription/
│   └── SharedUI/
├── Scripts/                    # bootstrap, generate-xcode, …
├── projectbrief.md
├── productContext.md
├── systemPatterns.md
├── techContext.md
├── progress.md
├── activeContext.md
├── AGENTS.md
└── CLAUDE.md -> AGENTS.md
```

### Which app should agents edit?

| Path | Role |
|------|------|
| **`Apps/iOS`**, **`Apps/macOS`** | **Canonical forward targets** for new product work. SwiftUI sources under `Sources/`; regenerate Xcode with **`Scripts/generate-xcode.sh`**. Chat here is still **in-memory** in `ChatView` until [Docs/ROADMAP.md](Docs/ROADMAP.md) P1 ships. |
| **`Apps/PIKAPIKA`** | **Reference** iOS app with committed `.xcodeproj`, `PetChatActions`, voice, SwiftData-backed chat. Use for patterns; do not assume new work lands here unless the task says so. |

Product milestones and checklists: **[Docs/ROADMAP.md](Docs/ROADMAP.md)** (not duplicated in Memory Bank).

## Dependency map (logical)

- **App targets** (`Apps/iOS`, `Apps/macOS`, `Apps/PIKAPIKA`, …) → **`import PikaCore`** (umbrella re-exports `PikaCoreBase` + `PikaCorePersistence`).
- **`PikaCoreBase`** → Apple frameworks only (Foundation, Security, LocalAuthentication, Combine; no SwiftData).
- **`PikaCorePersistence`** → SwiftData (`@Model` types); no dependency on `PikaCoreBase` (models are standalone).
- **`PikaCore` (umbrella)** → depends on `PikaCoreBase` + `PikaCorePersistence`; `@_exported import` both modules.
- **Tests (CLI)** → live in **`PikaCoreBase`** so CI does not require SwiftData macro plugins.

## Orchestration patterns

- **ETS / HTN:** Epic → Task → SubTask for any non-trivial body of work; log milestones in `progress.md`.
- **Delegation:** Heavy research, large codegen, or security review → delegate to specialized sub-agents; orchestrator keeps **dense summaries** only.
- **Verification loop:** Plan → execute candidates → ablate failures → **adversarial review** → **source-backed** claims for architecture and APIs.
- **Uncertainty:** If a fact is not verified, **stop** and say so; do not guess API signatures or platform behavior.

## Peer review

Before merging significant changes: at least one **contrarian** pass (separate agent or human) for logic gaps, concurrency hazards, and data-loss risks—especially around persistence and sync.
