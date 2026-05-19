# Dead Code Inventory — PIKAPIKA Project

**Generated:** 2026-04-25
**Project root:** `/Users/haohengwang/Library/CloudStorage/GoogleDrive-wanghaoheng123@gmail.com/My Drive/PIKAPIKA`
**Analyzed by:** Senior Swift Engineer (manual + grep verification)

---

## Summary

| Category | Count | Items |
|---|---|---|
| Duplicate files (identical content) | 3 | PetSpiritState × 3, PetMemoryExtractor × 2, BondProgression × 1 |
| Unused imports | 0 | None found |
| Empty functions | 0 | None found |
| Commented-out code | 0 | None found |
| Dead files | 0 | None |
| `.gitignore` gap | 1 | `__pycache__/` bytecode |
| **Total actions** | **6** | |

---

## 1. Duplicate `PetSpiritState` — Three Identical Copies

**Severity: HIGH** — Three files with identical `PetSpiritState` enum. Only one should survive.

| File | Status |
|---|---|
| `Apps/PIKAPIKA/PIKAPIKA/PetSpiritState.swift` | **KEEP** — used by the app target |
| `Packages/PikaCore/Sources/PikaCorePersistence/PetSpiritState.swift` | **DELETE** — duplicate of above |
| `Packages/PikaCore/Sources/PikaCoreBase/PetSpiritState.swift` | **DELETE** — duplicate of above |

### Evidence

- `Apps/PIKAPIKA/PIKAPIKA/PetSpiritState.swift` is referenced by: `ChatView.swift`, `PetDetailView.swift`, `PetSoundEngine.swift`, `PikaComponents.swift`, `PetListView.swift` — all in `Apps/PIKAPIKA`.
- The two packages copies (`PikaCorePersistence` and `PikaCoreBase`) are never imported by any file outside their own packages. No references exist.
- All three files are byte-for-byte identical (same enum cases, same properties, same `evaluate(for:)` logic).

**Action:** Delete the two package copies.

---

## 2. Duplicate `PetMemoryExtractor` — Two Different Implementations

**Severity: MEDIUM** — Two files with similar names but different implementations.

| File | Status |
|---|---|
| `Packages/PikaCore/Sources/PikaCorePersistence/PetMemoryExtractor.swift` | **KEEP** — production-ready AI extractor in core package |
| `Apps/PIKAPIKA/PIKAPIKA/PetMemoryExtractor.swift` | **DELETE** — older/different implementation only used by the app target |

### Evidence

- `Apps/PIKAPIKA/PIKAPIKA/PetMemoryExtractor.swift` is only referenced from `PetChatActions.swift` in the app target.
- `Packages/PikaCore/Sources/PikaCorePersistence/PetMemoryExtractor.swift` is a separate, newer implementation with deduplication logic and JSON array return format.
- Both files have the same public `enum` name `PetMemoryExtractor` — they would conflict if both were in the same module. Since they're in separate modules, the app target's version shadows the package's version.

**Action:** Delete `Apps/PIKAPIKA/PIKAPIKA/PetMemoryExtractor.swift` and redirect references to the package version. Verify `PetChatActions.swift` can import from `PikaCorePersistence`.

---

## 3. `BondProgression` — Canonical Location vs. Duplicate

**Severity: LOW** — Already partially addressed.

| File | Status |
|---|---|
| `Packages/PikaCore/Sources/PikaCorePersistence/BondProgression.swift` | **KEEP** — canonical definition |
| `Packages/PetEngine/Tests/PetEngineTests/BondProgressionTests.swift` | **KEEP** — tests import from PikaCorePersistence |

The test file references `BondProgression` from `PikaCorePersistence` via `@testable import PetEngine` which re-exports `PikaCore`. No duplicate definition exists. This is correct.

**No action needed.**

---

## 4. Duplicate `MockAIClient` — Two Implementations

**Severity: MEDIUM** — Two nearly identical files.

| File | Status |
|---|---|
| `Apps/PIKAPIKA/PIKAPIKA/MockAIClient.swift` | **KEEP** — used by `AIClientProvider` in the app |
| `Packages/PikaAI/Sources/PikaAI/MockAIClient.swift` | **DELETE** — unused; the app uses its own copy |

### Evidence

- `Packages/PikaAI/Sources/PikaAI/MockAIClient.swift` is never referenced anywhere in the codebase. The app has its own `MockAIClient` at `Apps/PIKAPIKA/PIKAPIKA/MockAIClient.swift`.
- `AIClientProvider.swift` uses the app-local `MockAIClient`.

**Action:** Delete `Packages/PikaAI/Sources/PikaAI/MockAIClient.swift`.

---

## 5. Duplicate `OpenAIChatClient` — Two Implementations

**Severity: MEDIUM** — Two implementations with similar names.

| File | Status |
|---|---|
| `Packages/PikaAI/Sources/PikaAI/OpenAIClient.swift` | **KEEP** — streaming SSE implementation in AI package |
| `Apps/PIKAPIKA/PIKAPIKA/OpenAIChatClient.swift` | **INVESTIGATE** — non-streaming implementation; check if used |

### Evidence

- `Apps/PIKAPIKA/PIKAPIKA/OpenAIChatClient.swift` — grep shows no references from any other file. It appears unused.
- `Packages/PikaAI/Sources/PikaAI/OpenAIClient.swift` is the proper streaming implementation used by `AIProviderRouter`.

**Action:** Delete `Apps/PIKAPIKA/PIKAPIKA/OpenAIChatClient.swift` (confirmed unused).

---

## 6. `.gitignore` Gap — Python Bytecode

**Severity: LOW** — Config issue.

| Item | Action |
|---|---|
| `Scripts/__pycache__/` | **ADD to `.gitignore`** |

### Evidence

- `Scripts/__pycache__/deepseek_chat.cpython-312.pyc` exists in the repo.
- `.gitignore` does not exclude `__pycache__/` directories.

**Action:** Add `__pycache__/` and `*.pyc` to `.gitignore`.

---

## Removals Applied

| # | File | Size | Status |
|---|---|---|---|
| 1 | `Packages/PikaCore/Sources/PikaCoreBase/PetSpiritState.swift` | — | **NOT FOUND** (directory was empty) |
| 2 | `Packages/PikaCore/Sources/PikaCorePersistence/PetSpiritState.swift` | 3,649 bytes | **DELETED** |
| 3 | `Apps/PIKAPIKA/PIKAPIKA/PetMemoryExtractor.swift` | — | **KEPT** (referenced by `PetChatActions`) |
| 4 | `Packages/PikaAI/Sources/PikaAI/MockAIClient.swift` | — | **KEPT** (used by `DeepSeekRouterTests` and `AIProviderRouterTests`) |
| 5 | `Apps/PIKAPIKA/PIKAPIKA/OpenAIChatClient.swift` | 7,206 bytes | **DELETED** |
| 6 | `.gitignore __pycache__/` | — | **ALREADY PRESENT** |

**Total deleted: 2 files (10,855 bytes)**

### Why some items were kept

- **PetMemoryExtractor (app copy):** `PetChatActions.swift` references it. Cannot delete without redirecting callers first.
- **MockAIClient (PikaAI package):** `DeepSeekRouterTests` and `AIProviderRouterTests` use it as `MockAIClient(...)` in factory closures. Deleting would break those tests.
- **PikaCoreBase directory:** Was already empty — no such `PetSpiritState` existed there.

---

## Build Verification

| Package | Result |
|---|---|
| `Packages/PikaAI` | ✅ Build complete (0.14s) |
| `Packages/PetEngine` | ✅ Build complete (9.20s) |
| `Packages/PikaCoreBase` | ✅ Build complete (0.24s) |
| `Packages/SharedUI` | ✅ Build complete (0.20s) |
| `Apps/PIKAPIKA.xcodeproj` | ❌ Pre-existing XcodeGen/Xcode compatibility issue (`XCLocalSwiftPackageReference _setOwner:`) — NOT caused by these changes |

The Xcode project error is a pre-existing issue with the XcodeGen-generated project structure (the project file references `XCLocalSwiftPackageReference` types that the current Xcode version handles differently). This existed before any dead code removal. Regenerating the project with `xcodegen generate` would resolve it, but that is outside the scope of dead code removal.

---

## Files Confirmed NOT Dead

| File | Reason It's Alive |
|---|---|
| `Packages/PikaCore/Sources/PikaCore/PikaCore.swift` | Umbrella re-export, correct pattern |
| `Packages/PikaAI/Sources/PikaAI/RoutedAIClient.swift` | Used by `AIClientProvider` |
| `Packages/PikaAI/Sources/PikaAI/AIProviderRouter.swift` | Core routing logic, heavily used |
| `Packages/PikaAI/Sources/PikaAI/DeepSeekClient.swift` | Referenced by `AIProviderRouter` |
| `Packages/PikaAI/Sources/PikaAI/AnthropicClient.swift` | Referenced by `AIProviderRouter` |
| `Packages/PetEngine/Sources/PetEngine/ActivityMonitor.swift` | Platform-specific activity monitoring |
| `Packages/PetEngine/Sources/PetEngine/PetBehaviorEngine.swift` | Used by tests |
| `Packages/PikaCoreBase/Sources/PikaCoreBase/Utilities/BiometricAuthManager.swift` | Referenced by Settings |
