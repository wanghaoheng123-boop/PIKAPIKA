# PIKAPIKA macOS App — Code Audit Report

**Date:** Saturday Apr 25, 2026  
**Auditor:** Senior macOS/iOS Engineer (DeepSeek V4-Pro assisted)  
**Scope:** `/Apps/macOS/Sources/` + shared code (`Apps/Shared/Sources/`, `Packages/PikaCore/`, `Packages/PikaAI/`)

---

## Findings Summary

| # | Severity | File | Description |
|---|----------|------|-------------|
| 1 | MED | `PetHomeView.swift:193` | Redundant XP formula — `newXP - award.xp + cappedXP` is logically convoluted; simplified to `pet.bondXP += cappedXP` |
| 2 | MED | `PetHomeView.swift:212` | Silent `try? modelContext.save()` swallows errors; replaced with `do/catch` + `print` |
| 3 | MED | `PetChatScreen.swift:213` | `trimOldestIfNeeded` failure inside same `do` block as `save()` would cause cascade failure; separated with its own error handler |
| 4 | MED | `PetChatScreen.swift:272` | Same cascade-risk `trimOldestIfNeeded` issue after assistant row insert; fixed |
| 5 | LOW | `PetHomeView.swift:184` | Sleep action (`⌘S`) sets `selectedMood = .sleepy` but does not call `awardBond`; intentional or oversight — documented in issue list |

---

## Issue Detail

```
ISSUE-1: [MED] [PetHomeView.swift:193]
Description: The bond XP was calculated as `newXP - award.xp + cappedXP` where `newXP = BondProgression.apply(currentXP: pet.bondXP, award: award).newXP`. 
This computes `currentXP + award.xp - award.xp + cappedXP = currentXP + cappedXP`. The formula is mathematically equivalent but unnecessarily convoluted.
If `BondProgression.apply` ever accumulates side-effects (e.g., unlockedAnimations, level-up events), computing it with the full award then subtracting creates a temporal inconsistency.
Fix: Simplified to `pet.bondXP += cappedXP` — direct, clear, and safe.
```

```
ISSUE-2: [MED] [PetHomeView.swift:212]
Description: `try? modelContext.save()` silently discards any error. If the save fails after inserting a BondEvent, the event is orphaned in the context with no user indication and data is lost.
Fix: Replaced with a `do/catch` block that logs the error for debugging.
```

```
ISSUE-3: [MED] [PetChatScreen.swift:213]
Description: `try ConversationHistoryLimits.trimOldestIfNeeded(...)` inside the same `do` block as `modelContext.save()` means that if trim fails, the user row save is also considered failed, causing incorrect flow into the `catch` branch (userCommittedToStore set incorrectly, rollback attempted).
Fix: Wrapped trim call in its own nested `do/catch` so it cannot interfere with the save commit.
```

```
ISSUE-4: [MED] [PetChatScreen.swift:272]
Description: Same cascade-risk pattern: after inserting the assistant row, `save()` + `trimOldestIfNeeded` are chained. If trim fails, the already-saved assistant row is treated as a failure.
Fix: Same fix — nested error handler for trim call.
```

```
ISSUE-5: [LOW] [PetHomeView.swift:184]
Description: The Sleep quick-action button only sets `selectedMood = .sleepy` and does not call `awardBond`. Compare Feed and Play which both call `awardBond`. Either this is intentional (sleep is not rewardable) or an oversight. No comment documents the intent.
Fix: Either add `awardBond(.sleep)` or a comment `// No XP for sleep — mood-only action`.
```

---

## Concurrency Audit

**@MainActor consistency:** ✅ All view structs with mutating methods (`awardBond`, `sendNewUserMessage`, `completeAssistantTurn`) are correctly annotated `@MainActor` or called from `@MainActor` contexts. No `Task.detach` patterns found.

**Actor isolation:** ✅ `Pet`, `BondEvent`, `ConversationMessage`, `SeasonalEvent`, `PetMemoryFact` are `@Model` classes — SwiftData manages their actor context. All mutations happen on the main actor via UI-triggered paths.

**Task patterns:** ✅ `Task { await runConnectionProbe() }` in Settings uses proper structured concurrency. `DispatchQueue.main.asyncAfter` used for animation timing is safe.

---

## Nil-Safety & Error Handling Audit

**Force-unwrap:** ✅ None found in the macOS Sources. No `!` operator used on optionals.

**Implicitly unwrapped optionals:** ✅ None found.

**try! usage:** ✅ None found.

**Optional chaining:** ✅ `colors.first ?? PikaTheme.Palette.accentDeep` is safe. `persistedMessages.last?.role` in `canRetryAssistant` is safe.

**Missing nil guards:** ✅ `if let pet = pets.first` in ContentView and MenuBarContent covers the nil case gracefully.

---

## Logic Errors Audit

**Off-by-one:** ✅ `ForEach(0..<totalSteps, id: \.self)` is correct (0, 1, 2 for 3 steps).

**Boundary checks:** ✅ `cappedXP > 0` guard and `todayXP < BondProgression.dailyCap` guard are correct.

**Inverted logic:** ✅ `step <= currentStep` for progress indicator is correct.

**Operators:** ✅ `pet.streakCount == 1 ? "" : "s"` correctly pluralizes "day".

---

## Memory Leaks Audit

**Retain cycles:** ✅ No strong reference cycles found. `@Environment(\.modelContext)`, `@Query` bindings are framework-managed. SwiftData relationships use cascade delete rules, not manual strong refs.

**Closure capture:** ✅ `DispatchQueue.main.asyncAfter` in QuickActionRow closures captures `self` (PetHomeView) by value. For `@State`/`@StateObject` this is safe. No long-lived closures capture view structs.

**Delegate cycles:** ✅ Not applicable — no delegate pattern used.

---

## AppKit/SwiftUI Bridging Audit

**Scene lifecycle:** ✅ `PikaApp` correctly creates a single `ModelContainer` shared between `WindowGroup` and `MenuBarExtra` scenes — this is the recommended pattern to avoid SwiftData breaking in MenuBarExtra.

**MenuBarExtra:** ✅ `.modelContainer(modelContainer)` and `.menuBarExtraStyle(.window)` set correctly. Menu bar content is a proper SwiftUI view.

**NSApp.terminate:** ✅ `NSApp.terminate(nil)` is a hard quit — acceptable for Quit button.

**NSApp.activate:** ✅ `NSApp.activate(ignoringOtherApps: true)` correctly brings app to front.

---

## Security Audit

**Hardcoded keys:** ✅ No API keys or secrets in source code.

**Secret logging:** ✅ No `print` statements log secret values. Settings-only code uses `SecureField` and `KeychainHelper`. Biometric gate before revealing keys is properly implemented.

**Keychain patterns:** ✅ `KeychainHelper` uses `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` — correct security level for local-only keys.

**API header construction:** ✅ `request.setValue("Bearer \(apiKey)", ...)` uses string interpolation with class-private `apiKey`; not exposed to logs.

---

## Build Verification

**No critical compile-time issues found.** The codebase uses XcodeGen (`project.yml`) and should build via:

```bash
cd Apps/macOS
xcodegen generate
xcodebuild -project PikaApp.xcodeproj -scheme PikaApp -configuration Debug build
```

**Or with XcodeGen installed:**
```bash
xcodegen generate && xcodebuild -project PikaApp.xcodeproj -scheme PikaApp -configuration Debug build
```

---

## Files in Scope

| File | LOC | Notes |
|------|-----|-------|
| `Apps/macOS/Sources/PikaApp.swift` | 37 | Clean — scene + container setup |
| `Apps/macOS/Sources/ContentView.swift` | 32 | Clean — @Query + sheet |
| `Apps/macOS/Sources/PetHomeView.swift` | 404 | 2 fixes applied (XP formula, error logging) |
| `Apps/macOS/Sources/PetOnboardingView.swift` | 235 | Clean — step navigation |
| `Apps/macOS/Sources/ChatView.swift` | 10 | Thin wrapper — no issues |
| `Apps/macOS/Sources/SettingsView.swift` | 7 | Wrapper — no issues |
| `Apps/macOS/Sources/MenuBarContent.swift` | 31 | Clean — menu bar UI |
| `Apps/Shared/Sources/PetChatScreen.swift` | 341 | 2 cascade error handling fixes |
| `Apps/Shared/Sources/PikaSettingsContent.swift` | 183 | Clean — API key management with biometric gate |
| `Packages/PikaCore/Sources/PikaCorePersistence/BondProgression.swift` | 74 | Clean — Sendable, no side-effects |
| `Packages/PikaCore/Sources/PikaCorePersistence/Pet.swift` | 197 | Clean — @Model with relationships |
| `Packages/PikaCoreBase/Sources/PikaCoreBase/Utilities/KeychainHelper.swift` | 75 | Clean — thread-safe Keychain |
| `Packages/PikaCoreBase/Sources/PikaCoreBase/Utilities/BiometricAuthManager.swift` | 34 | Clean — LAContext wrapper |

---

## Conclusion

The PIKAPIKA macOS app codebase is well-structured and follows modern Swift/SwiftUI patterns. No critical crashes, force-unwraps, or security breaches were found. The primary improvement area is **error resilience** — several `try?` calls silently swallow failures that could cause data loss. These have been patched. No actor isolation bugs, no retain cycles, and no hardcoded secrets.

**Action items:**
- ✅ XP cap formula simplified
- ✅ Bond event save error now logged
- ✅ Trim failures isolated from save commits
- ⬜ Optional: Add comment to Sleep action documenting intentional no-XP design
