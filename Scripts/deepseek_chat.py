#!/usr/bin/env python3
"""One-shot non-streaming chat to DeepSeek v4-pro (OpenAI-compatible API).

Reads DEEPSEEK_API_KEY from the environment. Prompt from argv joined by spaces,
or stdin if argv is empty.
"""
from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.request

URL = "https://api.deepseek.com/v1/chat/completions"


def main() -> int:
    key = (os.environ.get("DEEPSEEK_API_KEY") or "").strip()
    if not key:
        print("deepseek_chat: set DEEPSEEK_API_KEY (see .env.template)", file=sys.stderr)
        return 1

    if len(sys.argv) > 1:
        user = " ".join(sys.argv[1:]).strip()
    else:
        user = sys.stdin.read().strip()

    if not user:
        print("deepseek_chat: pass a prompt as args or stdin", file=sys.stderr)
        return 1

    body = {
        "model": "deepseek-v4-pro",
        "temperature": 0.2,
        "stream": False,
        "thinking": {"type": "enabled"},
        "reasoning_effort": "high",
        "messages": [
            {
                "role": "system",
                "content": (
                    "You are a staff software engineer for a Swift/SwiftUI Apple-platform monorepo (PIKAPIKA). "
                    "Give concrete, repo-aware answers: name likely packages/paths, call out risks, and suggest tests. "
                    "If information is missing, say what you need instead of inventing APIs."
                ),
            },
            {"role": "user", "content": user},
        ],
    }

    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(
        URL,
        data=data,
        method="POST",
        headers={
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
        },
    )

    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            raw = resp.read().decode("utf-8")
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8", errors="replace")
        print(err_body, file=sys.stderr)
        return e.code if isinstance(e.code, int) else 3

    try:
        payload = json.loads(raw)
    except json.JSONDecodeError:
        print(raw, file=sys.stderr)
        return 2

    if payload.get("error"):
        print(json.dumps(payload["error"], indent=2), file=sys.stderr)
        return 3

    choices = payload.get("choices") or []
    if not choices:
        print(json.dumps(payload, indent=2), file=sys.stderr)
        return 4

    msg = (choices[0] or {}).get("message") or {}
    content = msg.get("content")
    if isinstance(content, str) and content.strip():
        print(content.strip())
        return 0
    if isinstance(content, list):
        parts: list[str] = []
        for part in content:
            if isinstance(part, dict) and part.get("type") == "text" and part.get("text"):
                parts.append(str(part["text"]))
        out = "".join(parts).strip()
        if out:
            print(out)
            return 0

    print(json.dumps(msg, indent=2), file=sys.stderr)
    return 5


if __name__ == "__main__":
    raise SystemExit(main())
