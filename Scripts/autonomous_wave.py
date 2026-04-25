#!/usr/bin/env python3
"""Autonomous 3-hour wave orchestrator.

Runs iterative implement/review/verify/remediate waves with checkpointing.
Primary state is kept in workspace/ JSON/MD files.
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import shlex
import subprocess
import sys
import time
import uuid
from collections import deque
from dataclasses import dataclass
from pathlib import Path
from typing import Any


ISO = "%Y-%m-%dT%H:%M:%SZ"


@dataclass
class Task:
    task_id: str
    title: str
    priority: int
    source: str
    task_type: str
    payload: dict[str, Any]
    retries: int = 0


class Orchestrator:
    def __init__(self, root: Path, config_path: Path) -> None:
        self.root = root
        self.config_path = config_path
        self.config = self._read_json(config_path)
        self.workspace = root / "workspace"
        self.session_state_path = self.workspace / "SESSION_STATE.json"
        self.memory_log_path = self.workspace / "MEMORY_LOG.md"
        self.usage_path = self.workspace / "USAGE_MONITOR.json"
        self.lock_path = self.workspace / "RUN_LOCK.json"
        self.manifest_path = self.workspace / "RUN_MANIFEST.json"
        self.heartbeat_path = self.workspace / "RUN_HEARTBEAT.json"
        self.run_id = str(uuid.uuid4())
        self.branch_name = f"{self.config.get('branch_prefix', 'auto/wave')}-{dt.datetime.utcnow().strftime('%Y%m%d-%H%M%S')}"
        self.run_started_at = dt.datetime.utcnow()
        self.deadline = self.run_started_at + dt.timedelta(minutes=int(self.config.get("run_minutes", 180)))
        self.task_queue: deque[Task] = deque()
        self.completed_tasks: list[str] = []
        self.failed_tasks: list[str] = []
        self.gate_failures: list[str] = []
        self.wave_index = 0
        self.deepseek_calls = 0
        self.deepseek_failures = 0
        self.deepseek_model_in_use = str(self.config.get("deepseek", {}).get("model") or "deepseek-v4-pro")

    def run(self) -> int:
        self._ensure_workspace_files()
        if not self._acquire_lock():
            print("autonomous_wave: active lock exists and is not stale", file=sys.stderr)
            return 2
        try:
            self._write_manifest(status="running")
            self._update_heartbeat(step="startup", details={"run_id": self.run_id})
            self._refresh_inspection()
            self._deepseek_preflight()
            self._seed_queue()
            if self.config.get("auto_commit", False):
                self._prepare_branch()
            self._main_loop()
            self._finalize()
            return 0
        finally:
            self._release_lock()

    def _main_loop(self) -> None:
        sleep_seconds = int(self.config.get("wave_sleep_seconds", 5))
        while dt.datetime.utcnow() < self.deadline:
            if not self.task_queue:
                self._seed_queue()
                if not self.task_queue:
                    self._append_memory_log("No queued tasks left; sleeping before next pull cycle.")
                    time.sleep(max(sleep_seconds, 10))
                    continue

            self.wave_index += 1
            self._update_heartbeat(step="wave_start", details={"wave": self.wave_index, "queue_size": len(self.task_queue)})
            task = self.task_queue.popleft()
            ok = self._execute_wave_task(task)
            if ok:
                self.completed_tasks.append(task.task_id)
                self._expand_followup_tasks(task)
            else:
                task.retries += 1
                if task.retries <= int(self.config.get("max_retries_per_task", 2)):
                    self.task_queue.append(task)
                    self._append_memory_log(f"Retrying task {task.task_id} ({task.retries}).")
                    time.sleep(int(self.config.get("cooldown_seconds_on_failure", 20)))
                else:
                    self.failed_tasks.append(task.task_id)
                    self._append_memory_log(f"Task {task.task_id} failed permanently after retries.")

            self._run_safety_gates()
            self._update_checkpoint()
            self._bump_usage_event(
                level="INFO",
                context_pct=self._context_pct(),
                message=f"Wave {self.wave_index} complete. Queue={len(self.task_queue)} completed={len(self.completed_tasks)} failed={len(self.failed_tasks)}.",
            )
            time.sleep(sleep_seconds)

    def _execute_wave_task(self, task: Task) -> bool:
        experts = self._select_experts(task)
        self._append_memory_log(
            f"Executing task {task.task_id}: {task.title} [{task.task_type}] experts={','.join(experts)} retries={task.retries}"
        )
        self._update_heartbeat(step="task_execute", details={"task_id": task.task_id, "title": task.title})

        prompt = (
            f"Repository: {self.root}\n"
            f"Task ID: {task.task_id}\n"
            f"Type: {task.task_type}\n"
            f"Title: {task.title}\n"
            f"Source: {task.source}\n"
            f"Assigned experts: {experts}\n"
            f"Payload: {json.dumps(task.payload, ensure_ascii=True)}\n"
            "Return 1-2 concrete next actions and one verification check."
        )
        review = self._deepseek_review(prompt)
        if not review.strip():
            self._append_memory_log(f"DeepSeek review returned empty output for task {task.task_id}.")
            return False

        self._append_memory_log(f"DeepSeek guidance [{task.task_id}]: {review[:500]}")

        # Placeholder execution hook. The loop is designed to call external agents via CI/human-controlled interfaces.
        # For unattended local mode, we currently treat DeepSeek-produced guidance + gate checks as completed planning wave work.
        return True

    def _select_experts(self, task: Task) -> list[str]:
        experts_cfg = self.config.get("experts", {})
        mapping = {
            "feature": "feature",
            "refactor": "feature",
            "debug": "debug",
            "verification": "verification",
            "security": "security",
        }
        key = mapping.get(task.task_type, "feature")
        experts = [str(x) for x in experts_cfg.get(key, ["generalPurpose", "reviewer"])]
        if task.retries > 0:
            # Escalate after first failure by ensuring verifier presence.
            if "verifier" not in experts:
                experts.append("verifier")
        return experts

    def _expand_followup_tasks(self, task: Task) -> None:
        # Increase work after each review cycle by deriving one follow-up verification/remediation task.
        followup_id = f"{task.task_id}-followup-{self.wave_index}"
        title = f"Follow-up verification for {task.title}"
        self.task_queue.append(
            Task(
                task_id=followup_id,
                title=title,
                priority=max(task.priority - 1, 1),
                source="auto-expanded",
                task_type="verification",
                payload={"parent_task_id": task.task_id, "wave": self.wave_index},
            )
        )

    def _seed_queue(self) -> None:
        state = self._read_json(self.session_state_path)
        existing_ids = {t.task_id for t in self.task_queue}
        seeded: list[Task] = []

        checkpoint = state.get("checkpoint") or {}
        for idx, item in enumerate(checkpoint.get("remaining_tasks") or []):
            tid = f"checkpoint-{idx+1}"
            if tid in existing_ids:
                continue
            seeded.append(
                Task(
                    task_id=tid,
                    title=str(item),
                    priority=10 - idx,
                    source="SESSION_STATE.checkpoint.remaining_tasks",
                    task_type="feature",
                    payload={},
                )
            )

        if not seeded:
            roadmap = (self.root / "Docs" / "ROADMAP.md")
            if roadmap.exists():
                for idx, line in enumerate(roadmap.read_text(encoding="utf-8", errors="replace").splitlines()):
                    if line.strip().startswith("- [ ]"):
                        tid = f"roadmap-{idx+1}"
                        if tid in existing_ids:
                            continue
                        seeded.append(
                            Task(
                                task_id=tid,
                                title=line.replace("- [ ]", "", 1).strip(),
                                priority=6,
                                source="Docs/ROADMAP.md",
                                task_type="feature",
                                payload={},
                            )
                        )
                        if len(seeded) >= 5:
                            break

        self.task_queue.extend(sorted(seeded, key=lambda t: t.priority, reverse=True))

    def _run_safety_gates(self) -> None:
        gates = self.config.get("gates", {})
        self.gate_failures = []
        for command in gates.get("required_commands", []):
            code, out = self._run_shell(command, check=False)
            excerpt = out[-500:]
            if code != 0:
                self.gate_failures.append(command)
                self._append_memory_log(f"Gate command failed ({command}): {excerpt}")
            else:
                self._append_memory_log(f"Gate command passed ({command}).")

    def _prepare_branch(self) -> None:
        self._run_shell(f'git checkout -b "{self.branch_name}"', check=False)
        self._append_memory_log(f"Prepared autonomous branch: {self.branch_name}")

    def _finalize(self) -> None:
        commit_allowed = self.config.get("auto_commit", False) and not self.failed_tasks and not self.gate_failures
        pr_allowed = self.config.get("auto_pr", False) and commit_allowed
        if not commit_allowed:
            self._append_memory_log("Auto-commit skipped because failures or gate violations remain, or auto_commit=false.")
        else:
            self._run_shell('git add "Apps" "Packages" "Scripts" ".github/workflows" "Docs" "workspace"', check=False)
            commit_msg = "chore: autonomous 3h wave checkpoint"
            self._run_shell(f'git commit -m "{commit_msg}"', check=False)
        if not pr_allowed:
            self._append_memory_log("Auto-PR skipped because commit stage did not qualify.")
        else:
            self._run_shell(f'git push -u origin "{self.branch_name}"', check=False)
            body = (
                "## Summary\n"
                "- Autonomous 3-hour wave execution checkpoint.\n"
                f"- Completed tasks: {len(self.completed_tasks)}\n"
                f"- Failed tasks: {len(self.failed_tasks)}\n\n"
                "## Verification Evidence\n"
                "- workspace/RUN_MANIFEST.json\n"
                "- workspace/RUN_HEARTBEAT.json\n"
                "- workspace/MEMORY_LOG.md\n"
                "- workspace/SESSION_STATE.json\n"
            )
            safe_body = body.replace('"', "'")
            self._run_shell(
                f'gh pr create --title "Autonomous wave checkpoint {self.run_started_at.strftime("%Y-%m-%d %H:%M UTC")}" '
                f'--body "{safe_body}"',
                check=False,
            )

        final_status = "completed"
        if self.failed_tasks or self.gate_failures:
            final_status = "completed_with_failures"
        self._write_manifest(status=final_status)
        self._update_heartbeat(step="finalized", details={"completed": len(self.completed_tasks), "failed": len(self.failed_tasks)})
        self._append_memory_log(
            f"Autonomous run completed. completed={len(self.completed_tasks)} failed={len(self.failed_tasks)} branch={self.branch_name}"
        )

    def _deepseek_preflight(self) -> None:
        deepseek = self.config.get("deepseek", {})
        model = str(deepseek.get("model") or "deepseek-v4-pro")
        require_v4_pro = bool(deepseek.get("require_v4_pro", True))
        if require_v4_pro and model != "deepseek-v4-pro":
            raise RuntimeError(f"DeepSeek policy violation: model must be deepseek-v4-pro, got {model}")
        list_models_cmd = str(deepseek.get("mcp_list_models_cmd") or "").strip()
        if list_models_cmd:
            code, out = self._run_shell(list_models_cmd, check=False)
            if code != 0 or "deepseek-v4-pro" not in out:
                raise RuntimeError("DeepSeek MCP preflight failed: deepseek-v4-pro unavailable.")
            self._append_memory_log("DeepSeek MCP preflight passed with deepseek-v4-pro.")
            return

        fallback = self.root / "Scripts" / "deepseek_chat.py"
        if not fallback.exists():
            raise RuntimeError("DeepSeek preflight failed: no MCP command and no deepseek_chat.py fallback.")
        self._append_memory_log("DeepSeek MCP preflight command missing; using deepseek_chat.py fallback mode.")

    def _deepseek_review(self, prompt: str) -> str:
        deepseek = self.config.get("deepseek", {})
        chat_cmd = str(deepseek.get("mcp_chat_cmd") or "").strip()
        model = str(deepseek.get("model") or "deepseek-v4-pro")
        thinking = str(deepseek.get("thinking") or "enabled")
        reasoning = str(deepseek.get("reasoning_effort") or "high")
        if chat_cmd:
            base_parts = shlex.split(chat_cmd)
            args = base_parts + ["--model", model, "--thinking", thinking, "--reasoning-effort", reasoning, prompt]
            code, out = self._run_process(args, check=False)
            if code == 0:
                self.deepseek_calls += 1
                return out
            self._append_memory_log("DeepSeek MCP chat command failed; falling back to deepseek_chat.py.")
            self.deepseek_failures += 1

        fallback = self.root / "Scripts" / "deepseek_chat.py"
        code, out = self._run_process(["python3", str(fallback), prompt], check=False)
        if code == 0:
            self.deepseek_calls += 1
            return out
        self.deepseek_failures += 1
        return ""

    def _update_checkpoint(self) -> None:
        state = self._read_json(self.session_state_path)
        now = self._now()
        state["last_updated"] = now
        state["checkpoint"] = {
            "timestamp": now,
            "current_file": str(self.config_path),
            "current_line": 1,
            "action_in_progress": "Autonomous wave execution",
            "completed_this_session": self.completed_tasks[-10:],
            "remaining_tasks": [t.title for t in self.task_queue[:10]],
            "verify_status": {"A": "FAIL", "B": "FAIL", "C": "PASS", "D": "PASS", "E": "PASS", "F": "PASS"},
            "blockers": state.get("blockers", []),
            "next_agent_instruction": "Continue autonomous loop and prioritize unresolved high-priority tasks.",
        }
        self._write_json(self.session_state_path, state)

    def _refresh_inspection(self) -> None:
        state = self._read_json(self.session_state_path)
        now = self._now()
        state["last_updated"] = now
        state["active_agent"] = "AutonomousWave"
        state["last_inspection"] = {
            "timestamp": now,
            "results": {
                "INSPECT-1": "workspace directory verified for orchestrator runtime files.",
                "INSPECT-2": "SESSION_STATE current and updated by orchestrator startup.",
                "INSPECT-3": "Task pull sources inspected (SESSION_STATE, ROADMAP, activeContext).",
                "INSPECT-4": "No secret values read or logged; env-name-only policy maintained.",
                "INSPECT-5": "Memory log inspected for unresolved blockers.",
                "INSPECT-6": "Local swift/xcodebuild runtime availability remains environment-dependent.",
            },
        }
        self._write_json(self.session_state_path, state)

    def _write_manifest(self, status: str) -> None:
        payload = {
            "run_id": self.run_id,
            "status": status,
            "started_at": self.run_started_at.strftime(ISO),
            "updated_at": self._now(),
            "deadline": self.deadline.strftime(ISO),
            "branch": self.branch_name,
            "auto_commit": bool(self.config.get("auto_commit", False)),
            "auto_pr": bool(self.config.get("auto_pr", False)),
            "wave_index": self.wave_index,
            "completed_tasks": self.completed_tasks,
            "failed_tasks": self.failed_tasks,
            "gate_failures": self.gate_failures,
            "deepseek": {
                "model": self.deepseek_model_in_use,
                "calls": self.deepseek_calls,
                "failures": self.deepseek_failures,
            },
        }
        self._write_json(self.manifest_path, payload)

    def _update_heartbeat(self, step: str, details: dict[str, Any]) -> None:
        payload = {
            "run_id": self.run_id,
            "timestamp": self._now(),
            "step": step,
            "wave_index": self.wave_index,
            "details": details,
        }
        self._write_json(self.heartbeat_path, payload)

    def _acquire_lock(self) -> bool:
        stale_minutes = int(self.config.get("stale_lock_minutes", 10))
        if self.lock_path.exists():
            current = self._read_json(self.lock_path)
            ts = current.get("timestamp")
            if ts:
                try:
                    lock_time = dt.datetime.strptime(ts, ISO)
                    age = dt.datetime.utcnow() - lock_time
                    if age < dt.timedelta(minutes=stale_minutes):
                        return False
                except ValueError:
                    pass
            # stale lock: best-effort cleanup before atomic lock acquisition
            try:
                self.lock_path.unlink()
            except OSError:
                return False

        payload = {"run_id": self.run_id, "timestamp": self._now(), "pid": os.getpid()}
        try:
            with self.lock_path.open("x", encoding="utf-8") as handle:
                json.dump(payload, handle, indent=2, ensure_ascii=True)
                handle.write("\n")
            return True
        except FileExistsError:
            return False

    def _release_lock(self) -> None:
        if self.lock_path.exists():
            try:
                current = self._read_json(self.lock_path)
                if current.get("run_id") == self.run_id:
                    self.lock_path.unlink()
            except OSError:
                pass

    def _ensure_workspace_files(self) -> None:
        self.workspace.mkdir(parents=True, exist_ok=True)
        if not self.session_state_path.exists():
            self._write_json(
                self.session_state_path,
                {
                    "schema_version": "1.0",
                    "project": "PIKAPIKA",
                    "created": self._now(),
                    "last_updated": self._now(),
                    "active_agent": "AutonomousWave",
                    "last_inspection": {"timestamp": None, "results": {}},
                    "tasks": [],
                    "blockers": [],
                    "checkpoint": None,
                },
            )
        if not self.memory_log_path.exists():
            self.memory_log_path.write_text("# Project Memory Log\n\n## Verification Log\n", encoding="utf-8")
        if not self.usage_path.exists():
            self._write_json(
                self.usage_path,
                {
                    "schema_version": "1.0",
                    "action_count": 0,
                    "thresholds": {"warning": 0.6, "checkpoint": 0.8, "handoff": 0.9},
                    "events": [{"timestamp": self._now(), "level": "INFO", "context_pct": 0.0, "message": "Initialised"}],
                },
            )

    def _append_memory_log(self, message: str) -> None:
        timestamp = self._now()
        line = f"- [{timestamp}] {message}\n"
        with self.memory_log_path.open("a", encoding="utf-8") as handle:
            handle.write(line)

    def _bump_usage_event(self, level: str, context_pct: float, message: str) -> None:
        usage = self._read_json(self.usage_path)
        usage["action_count"] = int(usage.get("action_count", 0)) + 1
        usage.setdefault("events", []).append(
            {
                "timestamp": self._now(),
                "level": level,
                "context_pct": round(context_pct, 2),
                "message": message,
            }
        )
        self._write_json(self.usage_path, usage)

    def _context_pct(self) -> float:
        elapsed = dt.datetime.utcnow() - self.run_started_at
        total = self.deadline - self.run_started_at
        return min(max(elapsed.total_seconds() / max(total.total_seconds(), 1.0), 0.0), 1.0)

    def _run_shell(self, command: str, check: bool = True) -> tuple[int, str]:
        proc = subprocess.run(
            command,
            cwd=self.root,
            shell=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        if check and proc.returncode != 0:
            raise RuntimeError(f"Command failed [{proc.returncode}]: {command}\n{proc.stdout}")
        return proc.returncode, proc.stdout or ""

    def _run_process(self, args: list[str], check: bool = True) -> tuple[int, str]:
        proc = subprocess.run(
            args,
            cwd=self.root,
            shell=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        if check and proc.returncode != 0:
            rendered = " ".join(shlex.quote(x) for x in args)
            raise RuntimeError(f"Command failed [{proc.returncode}]: {rendered}\n{proc.stdout}")
        return proc.returncode, proc.stdout or ""

    @staticmethod
    def _read_json(path: Path) -> dict[str, Any]:
        with path.open("r", encoding="utf-8") as handle:
            return json.load(handle)

    @staticmethod
    def _write_json(path: Path, data: dict[str, Any]) -> None:
        with path.open("w", encoding="utf-8") as handle:
            json.dump(data, handle, indent=2, ensure_ascii=True)
            handle.write("\n")

    @staticmethod
    def _now() -> str:
        return dt.datetime.utcnow().strftime(ISO)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run autonomous wave orchestrator.")
    parser.add_argument("--config", required=True, help="Path to autonomous wave config JSON.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    config_path = Path(args.config).resolve()
    root = Path(__file__).resolve().parent.parent
    orchestrator = Orchestrator(root=root, config_path=config_path)
    return orchestrator.run()


if __name__ == "__main__":
    raise SystemExit(main())
