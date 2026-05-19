# PIKAPIKA Project Structure

This document defines the canonical folder layout used for ongoing app work, audits, and automation.

## Core Application Areas

- `Apps/PIKAPIKA/PIKAPIKA` - shared SwiftUI app module for cross-platform pet experience.
- `Apps/iOS` - iOS app shell and iOS-specific entry points.
- `Apps/macOS` - macOS app shell and macOS-specific entry points.
- `Apps/Shared/Sources` - shared feature surfaces across app targets (chat, subscriptions, settings).

## Reusable Packages

- `Packages/PikaCore` - pet domain models, bonding, persistence-facing logic.
- `Packages/PikaCoreBase` - base protocols/utilities shared by core and AI layers.
- `Packages/PikaAI` - provider routing, AI clients, secure network policy, SSE parser.
- `Packages/PikaSubscription` - StoreKit wrappers, entitlements, subscription products.
- `Packages/SharedUI` - reusable theme/components used by app targets.

## Automation and Operations

- `.github/workflows` - CI/CD workflows and security gates.
- `Scripts` - operational scripts (release policy, autonomous wave, health checks).
- `Docs` - runbooks, architecture/policy docs, release/process guidance.
- `workspace` - runtime state, audits, and cross-agent continuity files.

## Organization Rules

- Keep business/domain logic in `Packages/*`; avoid duplicating logic inside app targets.
- Keep app-target files focused on UI composition and platform lifecycle concerns.
- Keep workflow and script logic under `.github/workflows` and `Scripts` only.
- Keep temporary local artifacts out of source directories.

## Integrity Baseline

- Run `python Scripts/repo_health_check.py` before large refactors or release prep.
- No unresolved merge markers are allowed in tracked source/state files.
- Critical workspace JSON files must remain parseable.
