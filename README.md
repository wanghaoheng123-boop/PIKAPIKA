# PIKAPIKA

Shared workspace for the **PIKAPIKA** product. Core Swift code is split into:

- **`PikaCoreBase`** ([`Packages/PikaCoreBase`](Packages/PikaCoreBase)) — domain types, protocols, utilities (no SwiftData). **CLI-safe:** run `swift test` here for CI.
- **`PikaCore`** ([`Packages/PikaCore`](Packages/PikaCore)) — depends on `PikaCoreBase` + **SwiftData** persistence (`@Model`). Build the full library in **Xcode** (SwiftData macros are unreliable with bare command-line Swift on some setups).

### Run the iOS app (Xcode)

The app project is already created: open **[`Apps/PIKAPIKA/PIKAPIKA.xcodeproj`](Apps/PIKAPIKA/PIKAPIKA.xcodeproj)** in Xcode (do **not** use *File → New → Project*). You must keep **`Apps/`** and **`Packages/`** together when copying or uploading. Step-by-step: **[`Apps/PIKAPIKA/README.md`](Apps/PIKAPIKA/README.md)**.

## Memory Bank (agent continuity)

Orchestration and project state live in Markdown at the repo root:

| File | Purpose |
|------|---------|
| [`projectbrief.md`](projectbrief.md) | Mandate and objectives |
| [`productContext.md`](productContext.md) | UX, domain, kickoff snapshots |
| [`systemPatterns.md`](systemPatterns.md) | Architecture and workflows |
| [`techContext.md`](techContext.md) | Stack and tooling constraints |
| [`progress.md`](progress.md) | Append-only history |
| [`activeContext.md`](activeContext.md) | Current focus and handoffs |
| [`AGENTS.md`](AGENTS.md) | Sub-agent routing (`CLAUDE.md` points here) |

## Building and testing

### `PikaCoreBase` (command line)

```bash
cd Packages/PikaCoreBase
swift test
```

Tests use **Swift Testing** (`swift-testing` package) so they run without full **XCTest** from Xcode Command Line Tools alone.

### `PikaCore` (SwiftData umbrella)

`PikaCore` uses **SwiftData** (`@Model`). Command-line `swift build` / `swift test` may fail with `SwiftDataMacros` / `PersistentModelMacro` not found if SwiftData macro plugins are not loaded.

**Recommended:** Open `Packages/PikaCore/Package.swift` in **Xcode**, select the `PikaCore` scheme, then **Build** (⌘B).

**Platforms:** macOS 14+, iOS 17+ (see each `Package.swift`).

## Repository layout

```
PIKAPIKA/
├── Apps/PIKAPIKA/         # iOS SwiftUI app (Xcode project; depends on local PikaCore)
├── Packages/PikaCoreBase/ # Swift package: domain + tests (no SwiftData)
├── Packages/PikaCore/     # Swift package: SwiftData models + umbrella `import PikaCore`
├── AGENTS.md
├── CLAUDE.md              # symlink → AGENTS.md (see techContext if on Windows)
└── … Memory Bank files …
```

## Sync note

This tree may live on **Google Drive**. Avoid editing the same files concurrently on two machines; sync before you start work.
