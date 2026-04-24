# AGENTS — routing and skills

Central routing for **Master Orchestrator** and sub-agents. **Claude Code** and compatible tools read `CLAUDE.md`, which must mirror this file (symlink or duplicate).

## Orchestrator responsibilities

- Own **Memory Bank** freshness: `activeContext.md` before/after substantive work.
- Prefer **delegation** for deep research, large refactors, security review, and exhaustive test runs.
- Enforce **verification**: sources for architecture claims; no guessed APIs.

## Sub-agent selection (Cursor)

| Persona | When to use |
|--------|-------------|
| **explore** | Read-only codebase mapping, find definitions, broad search. |
| **debugger** | Repro failures, test failures, root-cause analysis. |
| **test-runner** | Automated test execution and CI-style fixes. |
| **verifier** | Post-task validation of completed work. |
| **generalPurpose** | Multi-step implementation when not read-only. |

Custom agents: `~/.cursor/agents/*.md` (see Cursor global rules).

## Skills library

Canonical skills: `~/.cursor/skills/<name>/SKILL.md` — use for domain workflows (e.g. `manuscript-manager`, `book-genesis`, scientific skills) when relevant.

## GitHub / research

- **Open-source patterns:** Prefer official docs and pinned repos; cite in `progress.md` or `systemPatterns.md` when decisions depend on them.
- **Academic claims:** Use appropriate research skills; do not invent citations.

## Memory Bank map

| File | Role |
|------|------|
| `projectbrief.md` | Mandate, audience, objectives |
| `productContext.md` | UX, domain, functional goals |
| `systemPatterns.md` | Architecture, patterns, dependency map, **which `Apps/*` tree is canonical** |
| `techContext.md` | Stack, tooling, env constraints |
| `progress.md` | Append-only history |
| `activeContext.md` | Current task, handoff, next steps |
| `AGENTS.md` | Canonical agent routing (keep `CLAUDE.md` in lockstep) |
| `CLAUDE.md` | Same routing rules as `AGENTS.md` (for tools that only read `CLAUDE.md`) |
| `Docs/ROADMAP.md` | Product milestones (P0–P6); checklist for what to build next |

## Anti-patterns

- Flooding the orchestrator with raw logs—delegate and summarize.
- Editing Memory Bank **secrets** (never store secrets here).
- Skipping peer review for security- or persistence-sensitive changes.

<!-- AGENT HOOK v1 -->
## Agent Hook (Claude Code)
Read AGENT.md fully before any action. All six rules are defined there.
Hooks directory for enforcement: .claude/hooks/ (PreToolUse, PostToolUse, Stop).
Use Stop hook to block task completion unless VERIFY A-F all pass.
Use PreToolUse to block writes to *.env, secrets/, *credential*, *token* paths.
