# Competitive Research Notes (Primary Sources)

Date: 2026-04-27
Scope: Transferable UX/process patterns for PIKAPIKA only (no direct broker/trading implementation in this repo).

## Sources used

### Moomoo (official)
- https://www.moomoo.com/us/feature/charts
- https://www.moomoo.com/us/manual/topic-14-6
- https://www.moomoo.com/ca/manual/topic-14-210
- https://www.moomoo.com/us/papertrading

### Panda (official / product pages)
- https://pandats.com/en/
- https://pandats.com/products/
- https://pandats.com/products/panda-trader/
- https://www.pandaterminal.com/

### GitHub (official repos)
- https://github.com/kernc/backtesting.py
- https://github.com/mementum/backtrader

## Fact-checked takeaways (transferable to PIKAPIKA)

1) Multi-view, quick context switching improves analysis flow
- Moomoo emphasizes watchlist-first workflows and multi-chart switching from the same view.
- Transfer to PIKAPIKA:
  - Keep "home -> insights -> action" in one screen where possible.
  - Add compact "today summary" + "latest event" + "quick actions" blocks without extra navigation.

2) Explicit simulation boundaries increase trust
- Moomoo paper trading clearly separates simulated outcomes from live outcomes.
- Transfer to PIKAPIKA:
  - Distinguish "estimated/generative insights" from persisted facts.
  - Show clear labels for local vs cloud responses and non-deterministic AI content.

3) Fast feedback loops + role-specific surfaces
- Panda product pages stress role-specific control surfaces (web manager, reporting, alerts).
- Transfer to PIKAPIKA:
  - Keep user-facing pet interactions simple, but expose diagnostics/reporting for advanced users in settings and audit views.
  - Preserve low-friction quick actions with visible cap/status indicators.

4) Reliability and observability are product features
- Panda emphasizes persistent logs, backups, and operational visibility.
- Transfer to PIKAPIKA:
  - Keep deterministic event trail (`BondEvent`) and capped reward logic centralized.
  - Expand regression tests around streak/date boundaries and capped XP behaviors.

5) Backtesting frameworks prioritize deterministic, offline reproducibility
- `backtesting.py` and `backtrader` emphasize repeatable runs, metrics, and optimization.
- Transfer to PIKAPIKA:
  - Prefer deterministic tests for algorithmic behavior (`BondProgression`, `PetInteractionStreak`, routing fallback) over manual QA.
  - Add edge-case tables and fixed-date harnesses rather than ad hoc runtime checks.

## Concrete actions now mapped to roadmap

- P2 bond loop:
  - Continue unifying event application and cap logic in one core path.
  - Add deterministic test matrix for streak/day/cap edge cases.
- P3/P4 quality:
  - Add explicit state labels and small diagnostics in settings/home.
  - Strengthen CI checks to keep behavior reproducible.

## Non-goals in this repository

- No broker integrations, order execution, market data ingestion, or securities recommendations.
- If a future QuantLab/trading product is requested, create a separate module/repo and reuse this quality-loop process.

