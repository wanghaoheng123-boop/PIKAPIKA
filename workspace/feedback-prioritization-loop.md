# Opt-in Feedback + Prioritization Loop (PIKAPIKA)

Date: 2026-04-27  
Backlog anchor: `workspace/audit-uiux.md`

## Goal

Create a repeatable, privacy-preserving loop:
`measure -> classify -> prioritize -> implement -> verify -> report`.

## Opt-in data policy

- Collect only if user explicitly opts in.
- No API keys, message bodies, or secrets.
- Event-level metadata only (screen, action, outcome, timestamp bucket, app version).

## Feedback channels (lightweight)

1. In-app micro-survey (1 question after key flows)
   - Onboarding completion
   - First chat session
   - Settings connection probe
2. Passive friction events
   - Empty state exits
   - Repeated retries/errors
   - Drop-off after failed action

## Priority scoring model

Each item gets:

- **Severity** (S): 1-5 (bug/user harm)
- **Frequency** (F): 1-5 (how often observed)
- **Effort** (E): 1-5 (engineering effort; lower is better)
- **Strategic fit** (P): 1-5 (roadmap relevance)

Score:
`priority = (2*S + 2*F + P) - E`

## Audit-UIUX backlog mapping

Pulled from `workspace/audit-uiux.md`:

### Tier A (next sprint)
- Dark mode asset completeness and usage consistency.
- Accessibility baseline: Dynamic Type, VoiceOver labels, >=44x44 tap targets.
- Empty/loading/error state consistency across chat/home/settings.

### Tier B
- Motion polish consistency (animation timing, spring curve normalization).
- Onboarding validation clarity (traits step and guidance copy).

### Tier C
- Cosmetic refinements and optional micro-interactions.

## Cadence

- Weekly triage:
  - Merge new feedback events + manual feedback notes.
  - Re-score backlog using model above.
  - Promote top 3 to active implementation.
- Release gate:
  - At least one Tier A item closed per cycle until Tier A is empty.

## Verification for each implemented item

- Unit/UI test added or updated.
- Regression check for adjacent flows.
- Brief entry appended to `progress.md`.

