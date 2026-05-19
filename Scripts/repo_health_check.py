#!/usr/bin/env python3
"""
Lightweight repository integrity checker for PIKAPIKA.

Checks:
- unresolved merge markers in source/docs/workspace files
- TODO/FIXME/BROKEN/UNTESTED/HACK markers in source files
- JSON parse validity for critical workspace runtime files
"""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Iterable

ROOT = Path(__file__).resolve().parents[1]
SCAN_DIRS = ["Apps", "Packages", "Scripts", "Docs", "workspace", ".github"]
IGNORE_DIR_NAMES = {".git", "node_modules", ".build", "DerivedData"}
TEXT_EXTENSIONS = {
    ".swift",
    ".md",
    ".yml",
    ".yaml",
    ".json",
    ".py",
    ".sh",
    ".ts",
    ".tsx",
    ".js",
    ".mjs",
    ".mdc",
}
MERGE_MARKER_RE = re.compile(r"^(<<<<<<<|=======|>>>>>>>)", re.MULTILINE)
TASK_TOKENS = ("TODO", "FIXME", "BROKEN", "UNTESTED", "HACK")

CRITICAL_JSON_FILES = [
    ROOT / "workspace" / "SESSION_STATE.json",
    ROOT / "workspace" / "USAGE_MONITOR.json",
    ROOT / "workspace" / "RUN_LOCK.json",
    ROOT / "workspace" / "RUN_HEARTBEAT.json",
    ROOT / "workspace" / "RUN_MANIFEST.json",
]


def iter_candidate_files() -> Iterable[Path]:
    for root_name in SCAN_DIRS:
        base = ROOT / root_name
        if not base.exists():
            continue
        for path in base.rglob("*"):
            if path.is_dir():
                continue
            if any(part in IGNORE_DIR_NAMES for part in path.parts):
                continue
            if path.suffix.lower() in TEXT_EXTENSIONS:
                yield path


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def run() -> int:
    merge_marker_hits: list[str] = []
    todo_hits: list[str] = []
    json_errors: list[str] = []

    for path in iter_candidate_files():
        rel = path.relative_to(ROOT)
        text = read_text(path)
        if MERGE_MARKER_RE.search(text):
            merge_marker_hits.append(str(rel))
        if path.suffix.lower() == ".swift" and any(token in text for token in TASK_TOKENS):
            todo_hits.append(str(rel))

    for json_path in CRITICAL_JSON_FILES:
        if not json_path.exists():
            continue
        try:
            json.loads(read_text(json_path))
        except Exception as exc:  # noqa: BLE001
            json_errors.append(f"{json_path.relative_to(ROOT)} -> {exc}")

    print("=== Repo Health Check ===")
    print(f"merge-markers: {len(merge_marker_hits)}")
    for item in merge_marker_hits[:25]:
        print(f"  - {item}")
    print(f"swift TODO-like markers: {len(todo_hits)}")
    for item in todo_hits[:25]:
        print(f"  - {item}")
    print(f"critical-json-errors: {len(json_errors)}")
    for item in json_errors:
        print(f"  - {item}")

    # Non-zero exit if data corruption indicators remain.
    if merge_marker_hits or json_errors:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(run())
