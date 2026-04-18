# PIKAPIKA

**GitHub:** [https://github.com/wanghaoheng123-boop/PIKAPIKA](https://github.com/wanghaoheng123-boop/PIKAPIKA)

### Clone for Xcode

1. **Xcode:** **File → Clone Repository…** → paste `https://github.com/wanghaoheng123-boop/PIKAPIKA.git` → choose a folder → **Clone**.
2. **Terminal:** `git clone https://github.com/wanghaoheng123-boop/PIKAPIKA.git`

**Primary (canonical) apps:** from repo root run **`bash Scripts/generate-xcode.sh`** (requires [XcodeGen](https://github.com/yonaskolb/XcodeGen)), then open **`Apps/iOS/Pika.xcodeproj`** or **`Apps/macOS/Pika.xcodeproj`** and **⌘R**.

**Legacy iOS app:** open **`Apps/PIKAPIKA/PIKAPIKA.xcodeproj`** (committed project; reference implementation for SwiftData chat and related flows).

After cloning, run **`swift test`** inside `Packages/PikaCoreBase` if you want to verify packages without SwiftData macros.

---

Shared workspace for the **PIKAPIKA** product. Core Swift code is split into:

- **`PikaCoreBase`** ([`Packages/PikaCoreBase`](Packages/PikaCoreBase)) — domain types, protocols, utilities (no SwiftData). **CLI-safe:** run `swift test` here for CI.
- **`PikaCore`** ([`Packages/PikaCore`](Packages/PikaCore)) — depends on `PikaCoreBase` + **SwiftData** persistence (`@Model`). Build the full library in **Xcode** (SwiftData macros are unreliable with bare command-line Swift on some setups).

### Run the apps (Xcode)

- **Pika (iOS / macOS):** generate with **[`Scripts/generate-xcode.sh`](Scripts/generate-xcode.sh)**, then open **`Apps/iOS/Pika.xcodeproj`** or **`Apps/macOS/Pika.xcodeproj`**.
- **PIKAPIKA (legacy iOS):** open **[`Apps/PIKAPIKA/PIKAPIKA.xcodeproj`](Apps/PIKAPIKA/PIKAPIKA.xcodeproj)** — details in **[`Apps/PIKAPIKA/README.md`](Apps/PIKAPIKA/README.md)**.

Keep **`Apps/`**, **`Packages/`**, and **`Scripts/`** together when copying or syncing the tree.

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
| [`Docs/ROADMAP.md`](Docs/ROADMAP.md) | Product milestones (P0, P1, …) — canonical checklist |

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
├── Apps/
│   ├── iOS/               # XcodeGen → Pika.xcodeproj (canonical iOS app sources)
│   ├── macOS/             # XcodeGen → Pika.xcodeproj
│   └── PIKAPIKA/          # Legacy iOS: PIKAPIKA.xcodeproj + reference SwiftData chat
├── Backend/               # Firebase (functions, rules)
├── Docs/                  # ROADMAP, ARCHITECTURE, …
├── Packages/              # PikaCore, PikaAI, PetEngine, PikaSync, PikaSubscription, SharedUI
├── Scripts/               # generate-xcode.sh, bootstrap, …
├── AGENTS.md
├── CLAUDE.md              # symlink → AGENTS.md (see techContext if on Windows)
└── … Memory Bank files …
```

## Sync note

This tree may live on **Google Drive**. Avoid editing the same files concurrently on two machines; sync before you start work.
