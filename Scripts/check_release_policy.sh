#!/usr/bin/env bash
set -euo pipefail

IOS_PROJECT_YML="Apps/iOS/project.yml"
MAC_PROJECT_YML="Apps/macOS/project.yml"
MODE="${1:-advisory}"

if [[ "$MODE" != "advisory" && "$MODE" != "strict" ]]; then
  echo "Usage: bash Scripts/check_release_policy.sh [advisory|strict]"
  exit 2
fi

if [[ ! -f "$IOS_PROJECT_YML" || ! -f "$MAC_PROJECT_YML" ]]; then
  echo "Missing XcodeGen project specs."
  exit 1
fi

extract_value() {
  local file="$1"
  local key="$2"
  rg -n "^[[:space:]]*${key}:[[:space:]]*\"?([^\"]+)\"?[[:space:]]*$" "$file" -r '$1' -o --no-line-number --no-filename | head -n 1
}

print_migration_path() {
  cat <<'EOF'
Migration path:
  1) Set DEVELOPMENT_TEAM in Apps/iOS/project.yml and Apps/macOS/project.yml
  2) Bump MARKETING_VERSION above bootstrap (e.g. 0.1.0 -> 0.2.0)
  3) Keep CURRENT_PROJECT_VERSION numeric and identical across iOS/macOS
  4) Re-run this script in strict mode before cutting release branch
EOF
}

violations=()

record_violation() {
  local message="$1"
  violations+=("$message")
}

IOS_MARKETING_VERSION="$(extract_value "$IOS_PROJECT_YML" "MARKETING_VERSION")"
IOS_BUILD_VERSION="$(extract_value "$IOS_PROJECT_YML" "CURRENT_PROJECT_VERSION")"
IOS_TEAM="$(extract_value "$IOS_PROJECT_YML" "DEVELOPMENT_TEAM")"
MAC_MARKETING_VERSION="$(extract_value "$MAC_PROJECT_YML" "MARKETING_VERSION")"
MAC_BUILD_VERSION="$(extract_value "$MAC_PROJECT_YML" "CURRENT_PROJECT_VERSION")"
MAC_TEAM="$(extract_value "$MAC_PROJECT_YML" "DEVELOPMENT_TEAM")"

if [[ -z "$IOS_MARKETING_VERSION" || -z "$MAC_MARKETING_VERSION" ]]; then
  record_violation "Missing MARKETING_VERSION."
fi

if [[ "$IOS_MARKETING_VERSION" != "$MAC_MARKETING_VERSION" ]]; then
  record_violation "Marketing versions diverge: iOS=$IOS_MARKETING_VERSION macOS=$MAC_MARKETING_VERSION"
fi

if [[ -z "$IOS_BUILD_VERSION" || -z "$MAC_BUILD_VERSION" ]]; then
  record_violation "Missing CURRENT_PROJECT_VERSION."
fi

if ! [[ "$IOS_BUILD_VERSION" =~ ^[0-9]+$ && "$MAC_BUILD_VERSION" =~ ^[0-9]+$ ]]; then
  record_violation "Build versions must be numeric."
fi

if [[ "$IOS_BUILD_VERSION" != "$MAC_BUILD_VERSION" ]]; then
  record_violation "Build versions diverge: iOS=$IOS_BUILD_VERSION macOS=$MAC_BUILD_VERSION"
fi

if [[ "$IOS_TEAM" == "\"\"" || "$MAC_TEAM" == "\"\"" || -z "$IOS_TEAM" || -z "$MAC_TEAM" ]]; then
  record_violation "DEVELOPMENT_TEAM must be configured for release readiness."
fi

if [[ "${IOS_MARKETING_VERSION}" == "0.1.0" ]]; then
  record_violation "MARKETING_VERSION still at bootstrap value 0.1.0."
fi

if [[ ${#violations[@]} -eq 0 ]]; then
  echo "Release policy checks passed (${MODE})."
  exit 0
fi

echo "Release policy violations (${MODE}):"
for v in "${violations[@]}"; do
  echo "  - $v"
done
print_migration_path

if [[ "$MODE" == "strict" ]]; then
  exit 1
fi

echo "Advisory mode: not blocking this workflow."
exit 0
