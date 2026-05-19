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
| `Docs/DEEPSEEK_AGENT_SETUP.md` | Use DeepSeek **v4-pro** for planning/coding in Cursor, CLI, and terminal helpers |

## DeepSeek v4-pro (planning and coding support)

- In **Cursor**, when the **`user-deepseek`** MCP server is enabled, **prefer MCP** for DeepSeek work: use tool **`chat_completion`** with `model` **`deepseek-v4-pro`**, `thinking` enabled, and `reasoning_effort` **`high`** (or `max` when justified) for architecture, refactors, multi-step plans, and careful code review. Use **`completion`** for fill-in-the-middle code edits; call **`list_models`** when validating model IDs. Read each tool’s schema under `mcps/user-deepseek/tools/` before the first call. Details: [`Docs/DEEPSEEK_AGENT_SETUP.md`](Docs/DEEPSEEK_AGENT_SETUP.md) and [`.cursor/rules/deepseek-mcp.mdc`](.cursor/rules/deepseek-mcp.mdc).
- The PIKAPIKA app already routes in-app chat through DeepSeek when the user saves a key in Settings.
- **Fallback** when MCP is unavailable: [`Scripts/deepseek_chat.sh`](Scripts/deepseek_chat.sh) / [`Scripts/deepseek_chat.py`](Scripts/deepseek_chat.py) with `DEEPSEEK_API_KEY` (name only in [`.env.template`](.env.template)) for one-shot prompts—**never** paste secrets into issues, commits, or Memory Bank files.

## Anti-patterns

- Flooding the orchestrator with raw logs—delegate and summarize.
- Editing Memory Bank **secrets** (never store secrets here).
- Skipping peer review for security- or persistence-sensitive changes.

<!-- AGENT HOOK v1 -->
## Agent Hook (Codex CLI)
Read AGENT.md fully before any action. All six rules are defined there.
Session continuity: workspace/SESSION_STATE.json is the source of truth.
