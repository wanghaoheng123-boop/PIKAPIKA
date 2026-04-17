# Project brief — PIKAPIKA

## Mandate

Establish and maintain **PIKAPIKA** as a cross-platform product workspace whose core logic lives in the **PikaCore** Swift package: virtual pet domain models, bonding/progression, activity capture, and AI client interfaces—designed for **SwiftData** persistence and optional **CloudKit** sync.

Operate development under the **Universal Orchestration Protocol**: a Memory Bank for continuity across Cursor, Claude Code, and Antigravity; synchronized via Google Drive across MacBook, Mac Mini, and Windows PC; with **zero data loss** on handoff and **rigorous verification** before treating work as final.

## Target audience

- **End users:** People using the PIKAPIKA app experience (pet companion, streaks, work sessions, personalization).
- **Builders:** Engineers and AI agents editing this repo on multiple machines and tools.

## Primary objectives

1. **Correctness and safety:** Concurrency-aware Swift (`StrictConcurrency`), secure keychain/biometric patterns where applicable, clear data models.
2. **Continuity:** Memory Bank files remain the source of truth for project state; `activeContext.md` enables async resume.
3. **Scalability:** Keep `PikaCore` boundaries clean so app targets can consume the library without coupling orchestration docs to runtime code.

## Orchestration alignment

This brief is updated when the product mandate changes. Detailed UX and stack rules live in `productContext.md` and `techContext.md`.

**Execution authorization (2026-04-17):** User confirmed **`APPROVED`** to continue PIKAPIKA work after orchestration bootstrap; subsequent epics still use ETS planning and `progress.md` logging.
