# System patterns — PIKAPIKA

## Phase 1 meta-architecture decision (baseline retained)

**Decision:** Keep the **baseline Memory Bank** layout (`projectbrief`, `productContext`, `systemPatterns`, `techContext`, `progress`, `activeContext`, `AGENTS`).

**Rationale:** Community and handbook guidance (e.g. structured markdown for agent continuity—see Tweag *Agentic Coding Handbook* memory bank patterns) converges on a small set of human-editable files. Adding a custom finite-state machine spec or extra topology files is **not** justified until this repo grows multiple app targets or multi-package workflows that require explicit state charts.

**Revisit when:** Multiple long-running feature epics need parallel agent lanes with explicit gates; then consider a lightweight `state/` or `workflows/` folder with machine-readable definitions.

## Repository layout

```
PIKAPIKA/
├── Apps/PIKAPIKA/              # iOS SwiftUI app shell (`.xcodeproj`; local SPM link to PikaCore)
├── Packages/PikaCoreBase/      # Swift package: domain, protocols, utilities; `swift test` (Swift Testing)
├── Packages/PikaCore/          # Swift package: path-dep on PikaCoreBase; SwiftData `@Model` + umbrella `PikaCore`
├── projectbrief.md
├── productContext.md
├── systemPatterns.md
├── techContext.md
├── progress.md
├── activeContext.md
├── AGENTS.md
└── CLAUDE.md -> AGENTS.md
```

## Dependency map (logical)

- **App (future) / consumers** → **`import PikaCore`** (umbrella re-exports `PikaCoreBase` + `PikaCorePersistence`).
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
