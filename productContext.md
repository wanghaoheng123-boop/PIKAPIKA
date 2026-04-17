# Product context — PIKAPIKA

## Problem domain

A **virtual pet companion** with bond progression (XP, levels, streaks), **work-session presence** tracking, and **AI-assisted** interaction surfaces (via `AIClient` and related protocols). Data is modeled for **SwiftData** persistence and evolution toward cloud sync.

## User experience goals

- **Emotional continuity:** Pets feel persistent (name, species, appearance, personality traits).
- **Lightweight habit loop:** Streaks and check-ins reward regular engagement without punishing missed days harshly (product decisions may refine this).
- **Trust:** Biometric and keychain helpers follow platform conventions; no secrets in Memory Bank files.

## Functional goals (library scope)

- Represent **pets**, **bond events**, **activity** streams, and **pet state** in a testable, migration-friendly way.
- Expose **protocols** (e.g. activity sources, AI client) so app layers can plug implementations without forking core types.

## Non-goals (for this repo root)

- The Memory Bank does **not** replace version control history; it summarizes **intent**, **constraints**, and **current focus** for agents and humans.

## Kickoff snapshot — Universal Orchestration bootstrap (2026-04-17)

| PTCF field | Content |
|------------|---------|
| **Target audience / end user** | PIKAPIKA app users (virtual pet); engineers and AI agents maintaining this repo. |
| **Core features required** | (1) Memory Bank continuity across tools/devices (2) `PikaCore` domain models and protocols (3) orchestrated ETS planning with APPROVED gate for feature work (4) verification and peer-review discipline (5) `AGENTS.md` / `CLAUDE.md` routing parity. |
| **Technical stack constraints** | Swift 5.9, macOS 14 / iOS 17, SwiftPM, SwiftData; workspace on Google Drive. |
| **Known challenges / focus** | Drive sync conflicts; Windows symlink behavior for `CLAUDE.md`; StrictConcurrency correctness in `PikaCore`. |

## Update protocol

When the user provides a PTCF kickoff (Persona, Task, Context, Format), **update this file** if UX, features, or problem domain changes—then mirror the mandate in `projectbrief.md` if needed.
