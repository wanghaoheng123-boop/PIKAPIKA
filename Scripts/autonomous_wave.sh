#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_PATH="${1:-${ROOT_DIR}/Scripts/autonomous_wave_config.json}"

if [[ ! -f "${CONFIG_PATH}" ]]; then
  echo "autonomous_wave: config not found: ${CONFIG_PATH}" >&2
  exit 1
fi

python3 "${ROOT_DIR}/Scripts/autonomous_wave.py" --config "${CONFIG_PATH}"
