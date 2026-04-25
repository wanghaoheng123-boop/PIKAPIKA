# Autonomous Wave Runbook

This runbook defines how to start, monitor, resume, and stop the autonomous 3-hour wave orchestrator.

## Runtime entrypoints

- Primary script: `Scripts/autonomous_wave.py`
- Wrapper: `Scripts/autonomous_wave.sh`
- Config: `Scripts/autonomous_wave_config.json`
- CI workflow: `.github/workflows/autonomous-wave.yml`

## Start a run (local)

```bash
bash Scripts/autonomous_wave.sh Scripts/autonomous_wave_config.json
```

## Start a run (GitHub Actions)

- Open **Actions** -> **Autonomous Wave** -> **Run workflow**
- Optional inputs:
  - `run_minutes`
  - `auto_pr`

## Runtime state files

- `workspace/RUN_LOCK.json`: single-run lock and stale-lock recovery metadata
- `workspace/RUN_MANIFEST.json`: run summary, completed and failed tasks
- `workspace/RUN_HEARTBEAT.json`: latest wave/step details
- `workspace/SESSION_STATE.json`: inspection/checkpoint handoff state
- `workspace/MEMORY_LOG.md`: append-only timeline and verification notes
- `workspace/USAGE_MONITOR.json`: action cadence and checkpoint/handoff thresholds

## Scheduling and budget

- Default wall clock budget: 180 minutes
- Scheduled CI cadence: every 6 hours via cron
- Each wave performs:
  1. task selection
  2. DeepSeek-assisted review
  3. follow-up expansion
  4. safety gate execution
  5. checkpoint write

## DeepSeek policy

- Planning and review must target `deepseek-v4-pro`.
- MCP preflight behavior:
  - If `deepseek.mcp_list_models_cmd` is configured, it must confirm `deepseek-v4-pro`.
  - If MCP command is missing or fails, script logs fallback and uses `Scripts/deepseek_chat.py`.
- Chat policy:
  - model: `deepseek-v4-pro`
  - thinking: `enabled`
  - reasoning effort: `high`

## Multi-expert wave routing

- `feature/refactor`: `generalPurpose`, `reviewer`
- `debug`: `debugger`, `reviewer`
- `verification`: `test-runner`, `verifier`
- `security`: `verifier`, `reviewer`
- Retry escalation automatically appends `verifier` if a task fails and retries.

## Safety and gates

- Mandatory gate commands come from `gates.required_commands` in config.
- Default gate command:
  - `bash Scripts/check_release_policy.sh advisory`
- Auto-commit and auto-PR are allowed only when failed task count is zero.

## Recovery and stop

- Stale lock is automatically reclaimed based on `stale_lock_minutes`.
- To force-stop:
  1. terminate process
  2. inspect `workspace/RUN_HEARTBEAT.json`
  3. delete stale `workspace/RUN_LOCK.json`
  4. restart using same config

## Failure matrix

- DeepSeek unavailable:
  - If MCP fails and fallback script is available, continue in fallback mode.
  - If both fail, stop run and record blocker in `MEMORY_LOG.md`.
- Gate failures:
  - Keep running waves, add remediation follow-ups, skip commit/PR at finalize if unresolved.
- Git/PR failures:
  - Write errors to memory log and keep artifacts for manual follow-up.

## Manual override

- Set `auto_commit=false` and `auto_pr=false` in config for dry-run orchestration.
- Reduce risk by setting a shorter `run_minutes` for trial passes.
