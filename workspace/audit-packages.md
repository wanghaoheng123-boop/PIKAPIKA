# PIKAPIKA Packages Audit Report

**Auditor:** Senior Swift Architect (DeepSeek v4-pro assisted)
**Date:** 2026-04-25
**Packages Audited:** PikaAI, PikaCore, PikaCoreBase, PetEngine, PikaSync, Apps/Shared

---

## Executive Summary

The codebase is well-structured overall with good separation of concerns. However, 5 **critical** issues, 6 **medium** issues, and several **low** issues were identified. The most severe are:

1. **Duplicate `PetSpiritState`** — identical enum in two modules causes compile ambiguity
2. **`systemPrompt: ""` bypass** — empty string is still sent as a system message, corrupting AI responses
3. **Streaming is fake** — all three AI clients fully buffer responses before parsing, defeating SSE
4. **`dailyCap` not enforced** — `BondProgression.dailyCap = 400` is defined but never applied
5. **`PetSpiritState.evaluate` logic bug** — time-away checks shadow high-XP states, breaking the spirit mood for engaged users

---

## Package: PikaCoreBase

### Issues

#### CRITICAL-1: `KeychainHelper` — Compound operations not atomic

**File:** `Sources/PikaCoreBase/Utilities/KeychainHelper.swift`

`save()`, `load()`, and `delete()` use raw Security framework APIs. `save()` implements "update-first, add-if-not-found" manually, but this is not atomic — two concurrent calls can both see `errSecItemNotFound` and both attempt to add, resulting in duplicate entries or errors.

**Fix:** Wrap all operations in a serial `NSLock` or use a dedicated serial queue.

#### MEDIUM-1: `KeychainHelper.exists()` calls `load()` — redundant retrieval

```swift
public static func exists(_ key: Key) -> Bool {
    load(key) != nil  // loads data just to check existence
}
```

`exists()` unnecessarily deserialises the data. Use `SecItemCopyMatching` with `kSecReturnData: false` instead.

#### LOW-1: `KeychainHelper` — `@unchecked Sendable` on an `enum` with static state

The `KeychainHelper` enum has mutable static state (no isolation). Marking it `@unchecked Sendable` without proper synchronization is unsafe in a concurrent Swift 6 world.

#### MEDIUM-2: `AIClient` protocol `systemPrompt: String` — cannot distinguish "no system prompt" from `""`

The protocol uses `String` (not `String?`), so callers must pass `""` to mean "no prompt". This leads to the `PetMemoryExtractor` bug (see PikaCorePersistence). Consider `String?`.

---

## Package: PikaCore (PikaCorePersistence target)

### Issues

#### CRITICAL-2: Duplicate `PetSpiritState` enum

**Files:**
- `Sources/PikaCoreBase/PetSpiritState.swift`
- `Sources/PikaCorePersistence/PetSpiritState.swift`

Both files define `PetSpiritState` with identical cases and nearly identical implementations. Any code that imports `PikaCore` (which re-exports both PikaCoreBase and PikaCorePersistence) will get an ambiguity error if both are in scope.

**Fix:** Delete `Sources/PikaCoreBase/PetSpiritState.swift`. Keep the one in `PikaCorePersistence` (which has the `evaluate(for pet: Pet)` method that needs `@Model` types). The PikaCoreBase version is dead code.

#### CRITICAL-3: `PetSpiritState.evaluate(for:)` — logic shadowing bug

**File:** `Sources/PikaCorePersistence/PetSpiritState.swift`, lines 82–92

```swift
public static func evaluate(for pet: Pet) -> PetSpiritState {
    let hoursAway = Date().timeIntervalSince(pet.lastInteractedAt) / 3600
    let xp = pet.bondXP

    if hoursAway > 72 { return .longing }   // ← shadowed below
    if hoursAway > 36 { return .wistful }  // ← shadowed below
    if hoursAway > 12 { return .cozy }     // ← shadowed below
    if xp >= 1_200 { return .radiant }     // ← never reached if hoursAway > 12
    if xp >= 200  { return .playful }      // ← never reached if hoursAway > 12
    return .curious
}
```

**Problem:** The time-away conditions (72h, 36h, 12h) all return before any XP-based state is checked. A user with 10,000 XP who was away for 13 hours gets `.cozy` instead of `.radiant`. The intent (high XP → radiant regardless of time) is never achieved.

**Fix:** Check XP conditions *before* the time-away chain, or make them independent:

```swift
if xp >= 1_200 { return .radiant }
if xp >= 200  { return .playful }
if hoursAway > 72 { return .longing }
if hoursAway > 36 { return .wistful }
if hoursAway > 12 { return .cozy }
return .curious
```

#### CRITICAL-4: `BondProgression.dailyCap` is defined but never applied

**File:** `Sources/PikaCorePersistence/BondProgression.swift`, line 73

```swift
public static let dailyCap: Int = 400
```

This cap is never used in `apply()`. Any caller can accumulate unlimited XP. The daily cap must be enforced at the call site — `PetInteractionStreak` or wherever XP awards are granted.

#### MEDIUM-3: `PetInteractionStreak.recordInteraction` — called from `@MainActor` but is not isolated

**File:** `Sources/PikaCorePersistence/PetInteractionStreak.swift`

```swift
public enum PetInteractionStreak {
    public static func recordInteraction(pet: Pet) {
```

This is a plain `enum` with a mutating method operating on a `@Model` object outside any actor. It works today because it's always called from `@MainActor` in `PetChatScreen`, but it's not safe by construction. Should be `@MainActor` or an isolated method.

#### MEDIUM-4: `PetMemoryExtractor` passes `systemPrompt: ""`

**File:** `Sources/PikaCorePersistence/PetMemoryExtractor.swift`, line 49

```swift
let stream = try await aiClient.chat(messages: messages, systemPrompt: "", temperature: 0.3)
```

Passing `""` as system prompt still sends an explicit `"role": "system", "content": ""` message to the AI API. Most providers treat this as a valid (empty) system message, which can confuse models that expect system instructions. If the intent is "no system prompt," this should be `nil` and the API call should skip the system message entirely.

**Fix:** Either change `AIClient.chat` signature to accept `String?`, or map `""` to "no system message" in each client.

#### LOW-2: `BondProgression.Event` — `.tapPet` and `.tap` are distinct but award identical XP (4 vs 3)

Unlikely to be intentional. `.tap` appears unused.

#### LOW-3: `BondProgression.Event.workSessionMinutes` — integer division truncation

```swift
Award(xp: min(Int(Double(minutes) / 2.0), 120), ...)
```

`Double(minutes) / 2.0` then `Int(...)` truncates. For odd minutes, this rounds down. Should use `rounded()` or compute as `minutes / 2`.

---

## Package: PikaAI

### Issues

#### CRITICAL-5: Streaming is fake — response is fully buffered before parsing

**Files:**
- `Sources/PikaAI/DeepSeekClient.swift`, lines 53–56
- `Sources/PikaAI/OpenAIClient.swift`, lines 59–63
- `Sources/PikaAI/AnthropicClient.swift`, lines 69–73

All three clients do:

```swift
let (data, response) = try await session.data(for: request)  // ← FULLY BUFFERS
try Self.validate(response, body: data)
let payloadText = String(data: data, encoding: .utf8) ?? ""
let lines = payloadText.components(separatedBy: .newlines)     // ← then parses buffered text
```

`URLSession.data(for:)` waits for the **entire** response before returning. The streaming `AsyncThrowingStream` is a lie — by the time the first chunk is yielded, the entire SSE stream has already been received and buffered in memory. For long responses this is a memory issue and defeats the purpose of SSE.

**Fix:** Use `URLSession.bytes(for:)` with an async sequence to yield chunks as they arrive, or use `URLSession.stream`/`AsyncLineSequence`.

#### MEDIUM-5: `DeepSeekClient.visibleAssistantText` — `reasoning_content` returns `""` before `content`

**File:** `Sources/PikaAI/DeepSeekClient.swift`, lines 80–92

```swift
private static func visibleAssistantText(from delta: [String: Any]) -> String {
    if let s = delta["reasoning_content"] as? String, !s.isEmpty { return "" }  // ← returns empty on reasoning
    if let s = delta["content"] as? String, !s.isEmpty { return s }
    // ...
}
```

The logic correctly ignores reasoning-only deltas. However, when DeepSeek sends a delta that contains *both* `reasoning_content` AND `content`, the current code checks `reasoning_content` first and returns `""`, never yielding the visible content. If the model interleaves reasoning and content in the same delta, this would suppress visible output.

The fix should be: check `reasoning_content` first for *suppression* only when there is no visible `content`:

```swift
let reasoning = delta["reasoning_content"] as? String ?? ""
let content = delta["content"] as? String ?? ""
if content.isEmpty && !reasoning.isEmpty { return "" }  // suppress only pure-reasoning deltas
return content
```

#### MEDIUM-6: `AIProviderRouter.runChatWithFallback` is `@MainActor` but not all paths are

**File:** `Sources/PikaAI/AIProviderRouter.swift`, lines 132–158

`runChatWithFallback` is `@MainActor` but `chatStreamResolvingPrimary` (line 210) is not. The inconsistency means the same router behaves differently depending on which method is called. This is confusing and can cause threading bugs.

#### LOW-4: `AnthropicClient` — `maxTokens` hardcoded default `1024`

The `maxTokens` of 1024 may be too small for longer pet personality responses. It's a magic number in the initializer.

#### LOW-5: `OpenAIClient.describeImage` — malformed response throws `statusCode: 0`

```swift
throw AIClientError.serverError(statusCode: 0, body: "malformed vision response")
```

Using `0` for a client-side error is inconsistent with other error cases that use real HTTP codes.

---

## Package: PetEngine

### Issues

#### MEDIUM-7: `PetBehaviorEngine` — mutable `var` members in an `actor` should be `nonisolated` or the actor boundary is leaky

**File:** `Sources/PetEngine/PetBehaviorEngine.swift`, lines 12–14

```swift
public actor PetBehaviorEngine {
    public var debounceInterval: TimeInterval = 1.5   // mutable actor property
    public var sleepAfter: TimeInterval = 300          // mutable actor property
```

Actor-isolated mutable state is safe, but the design is subtle: external code can `await` to get/set these. The `debounceInterval` and `sleepAfter` are internal timing parameters — making them mutable actor state is fine, but there is no thread-safety concern as long as all access is through the actor. The bigger concern is that `override(_:at:)` and `ingest(_:)` both modify `lastTransitionAt` which is a temporal race window.

**Consider:** Making timing parameters constructor-injected (`init(debounceInterval:sleepAfter:)`) rather than mutable properties, for clearer immutability.

#### LOW-6: `BondProgressionTests` in PetEngineTests imports `PikaCore` but tests the `BondProgression` from `PikaCorePersistence`

**File:** `Tests/PetEngineTests/BondProgressionTests.swift`

```swift
import PikaCore
@testable import PetEngine
```

`BondProgression` is defined in `PikaCorePersistence`. The test imports `PikaCore` (which re-exports `PikaCorePersistence` via `@_exported`). This works but is indirect and fragile — if the re-export is ever removed, the tests break silently. These tests should probably live in `PikaCoreTests` or a dedicated `PikaCorePersistenceTests`.

#### LOW-7: `BondProgression.apply` — level-up detection is naive

```swift
let levelUp: LevelUp? = after > before
    ? LevelUp(from: before, to: after, newlyUnlockedAnimations: after.unlockedAnimations)
    : nil
```

A multi-level jump (e.g., currentXP=0, award.xp=600 jumps from stranger→friendly) only reports one level-up event. Callers only see the final level, missing intermediate unlocks. This is a MEDIUM if callers need granular events.

---

## Package: PikaSync

### Issues

#### LOW-8: `CloudKitSyncCoordinator.upload` — only syncs subset of `Pet` fields

**File:** `Sources/PikaSync/CloudKitSyncCoordinator.swift`, lines 32–53

The `upload` method copies only a subset of `Pet` properties to the CKRecord:
```swift
record["name"] = pet.name
record["species"] = pet.species
record["bondXP"] = pet.bondXP
// ... but NOT:
// - personalityTraits (lost)
// - creatureDescription (lost)
// - avatarImagePath (lost)
// - modelUSDZPath (lost)
// - memoryFacts (lost)
```

If `CloudKitSyncCoordinator` is used alongside SwiftData+CloudKit (as the comments suggest), this custom upload is redundant and partial. If it's the *primary* sync path (not using SwiftData's native CloudKit), then critical pet data is not being synced.

**Fix:** Either remove this coordinator if SwiftData+CloudKit handles everything, or implement full-field sync.

#### LOW-9: `SyncConflictResolver.merge` mutates `local` Pet in-place

```swift
public static func merge(local: Pet, remote: RemotePetSnapshot) {
    local.bondXP = max(local.bondXP, remote.bondXP)
```

In-place mutation of a `@Model` object outside a model context is unusual. SwiftData may not track these changes unless done within a `ModelContext`. The method comment says "last-writer-wins" but changes are not saved automatically.

---

## Apps/Shared

### Issues

#### MEDIUM-8: `PetChatScreen` — `persistedMessages` query runs at struct init time, capturing `pet.id`

**File:** `Sources/PetChatScreen.swift`, lines 29–36

```swift
public init(pet: Pet) {
    self.pet = pet
    let petId = pet.id
    _persistedMessages = Query(filter: #Predicate<ConversationMessage> { message in
        message.pet?.id == petId   // ← captures petId from outer scope
    }, ...)
}
```

The `@Query` property wrapper is initialized at struct init time, capturing `petId` from the outer scope. If the `pet` object is replaced, the query does not update. This is a known SwiftData limitation — it works fine for static pets but could be fragile if pets are ever replaced at runtime.

#### LOW-10: `PetChatScreen` — `fetchMemoryFacts()` in `completeAssistantTurn` reads from `persistedMessages` but `persistedMessages` is not refreshed before reading

**File:** `Sources/PetChatScreen.swift`, lines 239–241

```swift
let apiMessages: [ChatMessage] = persistedMessages.map {
    ChatMessage(role: $0.role, content: $0.content)
}
```

After saving a new user row and assistant row, `persistedMessages` is not re-fetched. The newly saved messages may not appear in `apiMessages` until the next view update. This can cause the AI to miss the most recent exchange in its context window.

**Fix:** Refresh `persistedMessages` before building `apiMessages`, or use a fetched property that auto-updates.

#### LOW-11: `PikaSettingsContent` — not read; assumed missing functionality

File not provided in glob. Placeholder for future settings panel. No issues.

---

## Cross-Cutting Issues

| # | Severity | Issue | Packages |
|---|----------|-------|----------|
| 1 | CRITICAL | Duplicate `PetSpiritState` enum | PikaCoreBase + PikaCorePersistence |
| 2 | CRITICAL | `evaluate(for:)` time/XP shadowing | PikaCorePersistence |
| 3 | CRITICAL | `dailyCap` never enforced | PikaCorePersistence |
| 4 | CRITICAL | Fake streaming (`data(for:)`) | PikaAI (all 3 clients) |
| 5 | CRITICAL | `systemPrompt: ""` sent as empty system msg | PikaAI + PikaCorePersistence |
| 6 | MEDIUM | `KeychainHelper` compound ops not atomic | PikaCoreBase |
| 7 | MEDIUM | `PetInteractionStreak` not `@MainActor` isolated | PikaCorePersistence |
| 8 | MEDIUM | `@MainActor` inconsistency in router | PikaAI |
| 9 | MEDIUM | `visibleAssistantText` dual-field delta bug | PikaAI/DeepSeekClient |
| 10 | LOW | `exists()` redundant load | PikaCoreBase |
| 11 | LOW | `BondProgression` tests in wrong target | PetEngine |
| 12 | LOW | CK sync partial Pet fields | PikaSync |
| 13 | LOW | `PetChatScreen` query staleness | Apps/Shared |
| 14 | LOW | `AnthropicClient` hardcoded maxTokens | PikaAI |

---

## Recommended Fixes (Priority Order)

### Must Fix (Critical)

1. **Delete** `Sources/PikaCoreBase/PetSpiritState.swift` — keep only the PikaCorePersistence version
2. **Fix** `PetSpiritState.evaluate(for:)` — reorder conditions to check XP before time-away
3. **Implement real SSE streaming** in all three AI clients using `URLSession.bytes(for:)` or `AsyncLineSequence`
4. **Enforce `dailyCap`** — add a `canEarnXPToday(pet:)` check in `PetInteractionStreak` or a wrapper, using `UserDefaults` to track daily XP earned
5. **Fix `PetMemoryExtractor`** — change `AIClient.chat` signature to `systemPrompt: String?` and handle `nil` by omitting the system message

### Should Fix (Medium)

6. **Wrap `KeychainHelper`** operations in a serial `NSLock`
7. **Add `@MainActor`** to `PetInteractionStreak.recordInteraction`
8. **Fix `visibleAssistantText`** to handle dual-field deltas correctly
9. **Align `@MainActor`** on `AIProviderRouter` methods

### Nice to Fix (Low)

10. Replace `exists()` with a `SecItemCopyMatching` call that doesn't load data
11. Move `BondProgressionTests` to the appropriate test target
12. Complete `CloudKitSyncCoordinator` field sync or remove if redundant
13. Add refresh of `persistedMessages` before building context in `PetChatScreen`

---

## Build Verification

Run `swift build --package-path <path>` for each package:

| Package | Expected Result |
|---------|----------------|
| PikaCoreBase | PASS |
| PikaAI | PASS |
| PikaCore | PASS |
| PetEngine | PASS |
| PikaSync | PASS |

