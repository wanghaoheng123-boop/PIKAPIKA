# Tech context — PIKAPIKA

## Stack

- **Language:** Swift (Swift tools 5.9 per `Package.swift`).
- **Packages:** `PikaCoreBase` (`Packages/PikaCoreBase/`) and aggregate `PikaCore` (`Packages/PikaCore/`; local path dependency on `PikaCoreBase`).
- **Platforms:** macOS 14+, iOS 17+.
- **Concurrency:** `StrictConcurrency` enabled on package targets.
- **Persistence:** SwiftData (`@Model`) in `PikaCorePersistence` (inside `PikaCore` package); CloudKit mentioned in comments as optional sync path.
- **Unit tests:** `PikaCoreBase` uses **XCTest** only (removed `swift-testing` so `swift test` works on Xcode 15 / Swift 5.10 CI images without a Swift 6-only dependency graph).

## Execution environments

- **Agents:** Cursor (this workspace), Claude Code, Antigravity—**same** Memory Bank on disk; always read `activeContext.md` before large edits.
- **Sync:** Google Drive–backed workspace; expect **latency** and occasional **conflict** if two machines edit the same file simultaneously. Prefer **pull/sync → edit → commit** discipline.

## Windows note (`CLAUDE.md`)

On **Windows**, symlinks may require Developer Mode or Git `core.symlinks=true`. If `CLAUDE.md` cannot be a symlink, use a **duplicate** of `AGENTS.md` or a short stub that points to `AGENTS.md` and document the exception in `progress.md`.

## Formatting and quality

- **Swift:** Match existing style in `Packages/PikaCore`; prefer small, testable units.
- **Memory Bank:** Markdown only; no secrets, API keys, or personal data.
- **Anti-laziness:** No `// ... rest unchanged` in delivered artifacts when the user requires full-file output; otherwise prefer minimal diffs for reviewability—clarify per task.

## Tooling

- **CLI CI:** `cd Packages/PikaCoreBase && swift test` — exercises domain logic without SwiftData.
- **Full library:** `PikaCore` — **SwiftData `@Model`:** macro expansion needs the **SwiftDataMacros** plugin; command-line `swift build` may fail with `SwiftDataMacros` not found; build **from Xcode** or a toolchain that loads SwiftData macros.
- **XcodeGen apps:** Canonical **Pika** iOS/macOS projects live under **`Apps/iOS`** and **`Apps/macOS`**. Regenerate Xcode with **`bash Scripts/generate-xcode.sh`** (requires XcodeGen on `PATH`), then open **`Apps/iOS/Pika.xcodeproj`** or **`Apps/macOS/Pika.xcodeproj`**. Legacy **`Apps/PIKAPIKA/PIKAPIKA.xcodeproj`** remains a separate, committed iOS target.
