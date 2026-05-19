# DeepSeek v4-pro — coding, planning, and agent support

This repo already uses **DeepSeek `deepseek-v4-pro`** inside the PIKAPIKA app (Keychain + `AIProviderRouter`). This document covers **how you and your agents** can use the same model for higher-quality planning and implementation support in Cursor, MCP, and terminals.

Official API reference: [DeepSeek API docs](https://api-docs.deepseek.com/).

## Parameters (OpenAI-compatible)

| Item | Value |
|------|--------|
| Base URL | `https://api.deepseek.com` |
| Chat path | `POST /v1/chat/completions` |
| Auth | `Authorization: Bearer <API_KEY>` |
| Model | `deepseek-v4-pro` |
| Default “thinking” (recommended for planning) | `"thinking": {"type": "enabled"}`, `"reasoning_effort": "high"` |

## 1) In-app (PIKAPIKA)

Add your DeepSeek key in **Settings**, pick a provider order that lists DeepSeek first if you want it to lead chat and fallbacks. No extra setup beyond a valid key from [platform.deepseek.com](https://platform.deepseek.com/api_keys).

## 2) Cursor MCP (`user-deepseek`) — primary for agents

When DeepSeek is enabled as an MCP server in Cursor, agents should **prefer MCP** over ad-hoc HTTP from the repo.

| Item | Detail |
|------|--------|
| MCP server id | `user-deepseek` (see `SERVER_METADATA.json` under your Cursor project `mcps/user-deepseek/`) |
| Tool discovery | Before the first call to any tool, read its JSON schema under `mcps/user-deepseek/tools/*.json` |
| Main chat tool | `chat_completion` — set `model` to **`deepseek-v4-pro`** for architecture, refactors, multi-step plans, and careful code review |
| Faster / cheaper | `deepseek-v4-flash` when latency matters and risk is low |
| Fill-in-the-middle | `completion` — defaults to `deepseek-v4-pro`; use for “complete this block between prompt and suffix” edits |
| Model validation | `list_models` — no parameters; call when unsure which model string is live |
| Multi-turn planning | `conversation_id` on `chat_completion` to persist context across calls in the MCP process; `reset_conversation` clears one id |
| Debugging | `include_raw_response=true` only when you need the raw provider payload |

**Recommended `chat_completion` payload (planning / design):**

- `model`: `deepseek-v4-pro`
- `thinking`: `{ "type": "enabled" }`
- `reasoning_effort`: `"high"` (or `"max"` when you need the strongest reasoning)
- `messages`: include a `system` message that pins repo facts (paths, constraints) and asks for structured output (headings, checklists, file lists).

**Response shape caveat:** some MCP responses may include both the final answer and a visible **Reasoning** section. For copy/paste into issues or commits, quote only the actionable portion, or tighten the system prompt (“no meta commentary; final answer only”).

## 3) Cursor (IDE model override, optional)

If you also wire Cursor’s chat/composer to DeepSeek directly, treat it as an **OpenAI-compatible** endpoint:

1. Open **Cursor Settings** → **Models** (wording varies by version).
2. Set **Base URL**: `https://api.deepseek.com`, **Model**: `deepseek-v4-pro`, and store the API key in Cursor (never in git).

This is optional when MCP already covers DeepSeek.

## 4) Terminal helper (planning / code review prompts)

The repo includes [`Scripts/deepseek_chat.sh`](../Scripts/deepseek_chat.sh) (wrapper) and [`Scripts/deepseek_chat.py`](../Scripts/deepseek_chat.py). They read **`DEEPSEEK_API_KEY`** from the environment (see [`.env.template`](../.env.template)), send one user message (argv or stdin), and print the assistant reply (non-streaming).

```bash
export DEEPSEEK_API_KEY="your_value_here"   # do not commit this
./Scripts/deepseek_chat.sh "Draft a migration plan for splitting PikaAI providers."
python3 Scripts/deepseek_chat.py "Draft a migration plan for splitting PikaAI providers."
```

Pipe context:

```bash
git diff | ./Scripts/deepseek_chat.sh "Review this diff for Swift 6 concurrency issues."
```

Use this when MCP is unavailable (e.g. non-Cursor environments).

## 5) Workflow tips (higher quality from agents)

- **Planning:** ask for file-level steps, risks, and test plan; paste `systemPatterns.md` excerpts or tree snippets instead of whole repos.
- **Coding:** paste compiler errors verbatim; reference symbols with `` `Package/...` `` paths so the model grounds in your layout.
- **Verification:** treat API answers as provisional until `swift test` / Xcode build passes locally.

## 6) Limitations

- **Images:** DALL·E-style generation remains OpenAI-backed in-app; DeepSeek is for chat / reasoning / optional vision per API support.
- **Rate limits:** use the router fallbacks in-app; in Cursor/MCP/CLI, retry or switch to `deepseek-v4-flash` if you hit 429.
