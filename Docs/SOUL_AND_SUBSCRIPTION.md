# Pet “SOUL” export, backup, and subscription (spec)

This document defines **product intent** and **technical direction** for annual subscription, data portability, and long-term companion continuity. Implementation is phased; align code with this spec as features land.

## Goals

- **Companion continuity:** Personality, bond progress, memories, and conversation history should feel continuous across app updates and device changes when the user chooses to keep their data.
- **Trust:** Users can **export** a portable archive (“SOUL”) they control; subscription state does not erase their archive.
- **Fair monetization:** Annual plan unlocks **cloud convenience** and **premium runtime** (per product roadmap); **read-only / limited** modes may apply when unsubscribed if required by economics—must be clearly disclosed before purchase.

## Definitions

| Term | Meaning |
|------|--------|
| **SOUL file** | A **versioned** archive (e.g. signed ZIP) containing pet identity, SwiftData-exportable records (or JSON mirrors), memory facts, conversation excerpts, bond metadata, and a manifest with checksums. |
| **Subscription** | StoreKit 2 annual product; see [`Packages/PikaSubscription`](../Packages/PikaSubscription) (`SubscriptionManager`, `Entitlements`). |

## Export format (v1 target)

1. **Manifest** — `manifest.json`: schema version, export timestamp, app build, list of files + SHA-256.
2. **Core** — `pet.json` (or SwiftData export): stable pet id, name, species, bond XP/level, personality traits, creature description, paths or inlined blobs for avatar references.
3. **Memories** — `memories.jsonl` or array: `PetMemoryFact`-like rows (content, category, importance, source, timestamps).
4. **Conversation** — optional capped export (e.g. last N messages per pet) to limit size.
5. **Assets** — optional folder for images referenced by relative paths.

**Integrity:** Include checksums in manifest; optionally encrypt with a user passphrase (post-MVP).

## Restore flow

1. User selects SOUL file (document picker).
2. App validates manifest version and checksums.
3. **Merge strategy** (pick one per release): replace pet with same id, or create new pet from import—document in release notes.
4. Run in **transaction** (SwiftData) and refresh UI.

## Subscription vs. export (policy sketch)

- **With active annual subscription:** full chat, sync features per roadmap, automatic backups if/when server sync exists.
- **After lapse:** product decision—options include: local-only chat with cached model keys empty until user renews; **read-only** pet home; or grace period. **Must match App Store guidelines** and in-app copy.
- **SOUL file without subscription:** user can **reinstall** and **import** SOUL to revive local state; cloud features remain gated until renewed.

## UX pillars (tie to roadmap)

- **Care without punishment:** streak breaks recover gently (copy + mechanics in `PetEngine` / UI).
- **Memory recall:** surface `PetMemoryFact` in prompts ([`PromptLibrary`](../Packages/PikaAI/Sources/PikaAI/PromptLibrary.swift)) and occasional UI “remember when…” moments.
- **Export reminder:** Settings → “Back up pet (SOUL)” with plain-language risk copy.

## Legal / App Store

- Disclose **what** is stored, **where**, and **subscription** limitations in privacy policy and paywall.
- If server stores data, add data deletion and export parity where required by jurisdiction.

## References in repo

- SwiftData models: [`Packages/PikaCore/Sources/PikaCorePersistence`](../Packages/PikaCore/Sources/PikaCorePersistence)
- StoreKit wrapper: [`Packages/PikaSubscription`](../Packages/PikaSubscription)
- Backend (optional push/sync): [`Backend/functions`](../Backend/functions)
