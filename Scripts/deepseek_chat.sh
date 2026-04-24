#!/usr/bin/env bash
# Thin wrapper for Scripts/deepseek_chat.py (DeepSeek v4-pro one-shot chat).
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
exec python3 "$DIR/deepseek_chat.py" "$@"
