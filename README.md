# PIKAPIKA

**GitHub:** [https://github.com/wanghaoheng123-boop/PIKAPIKA](https://github.com/wanghaoheng123-boop/PIKAPIKA)

### Clone for Xcode (smooth first run)

1. **Clone**
   - **Xcode:** **File → Clone Repository…** → `https://github.com/wanghaoheng123-boop/PIKAPIKA.git` → pick a local folder (avoid cloud-synced folders if builds feel flaky).
   - **Terminal:** `git clone https://github.com/wanghaoheng123-boop/PIKAPIKA.git` then `cd PIKAPIKA`.

2. **Generate the Pika Xcode projects (required once per clone)**  
   The canonical **iOS** and **macOS** apps are produced by [XcodeGen](https://github.com/yonaskolb/XcodeGen). From the repo root on a **Mac**:
   - **Easiest:** `bash Scripts/bootstrap.sh` — installs XcodeGen via **Homebrew** if missing, then runs `Scripts/generate-xcode.sh`.
   - **Manual:** install XcodeGen (`brew install xcodegen`), then `bash Scripts/generate-xcode.sh`.

3. **Open and run**
   - Open **`Apps/iOS/Pika.xcodeproj`** or **`Apps/macOS/Pika.xcodeproj`**.
   - Select the **Pika** scheme, choose an **iOS Simulator** or **My Mac**, press **⌘R**.
   - **Signing:** `DEVELOPMENT_TEAM` is blank in `project.yml`; for a real device, set your **Team** under the target’s **Signing & Capabilities** in Xcode.

4. **Before chat works**  
   Open **Settings** in the app, unlock with Face ID / Touch ID / password, and save at least one vendor API key (Anthropic and/or OpenAI).

**Legacy iOS app (optional):** open **`Apps/PIKAPIKA/PIKAPIKA.xcodeproj`** — committed project; see **[`Apps/PIKAPIKA/README.md`](Apps/PIKAPIKA/README.md)**.

**Quick package check (no SwiftData macros):** `cd Packages/PikaCoreBase && swift test`.

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

Tests use **XCTest** (no extra packages; runs on GitHub Actions `macos-14` with the default Xcode toolchain).

### `PikaAI` (providers + prompts)

The package depends on **`PikaCoreBase` only** (not `PikaCore`), so **`swift test` works from the command line** without SwiftData macro plugins—the same layout **Pika CI** uses.

```bash
cd Packages/PikaAI
swift test
```

App targets that need SwiftData models still add **`PikaCore`** as a separate dependency in Xcode.

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

## Cursor / Claude Code troubleshooting

If the IDE, Claude Code, or Swift indexing misbehaves (missing files, symlink errors, or very slow analysis), **clone the repo to a short ASCII-only path** on disk (for example `~/Developer/PIKAPIKA` on macOS or `C:\dev\PIKAPIKA` on Windows). Cloud-sync folders and **non-ASCII path segments** can break some toolchains. After moving, run `bash Scripts/bootstrap.sh` again before opening Xcode.
