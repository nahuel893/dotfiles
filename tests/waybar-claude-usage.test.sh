#!/usr/bin/env bash
# Offline test for scripts/waybar-claude-usage.sh (uses a fixture, no network).
set -euo pipefail
cd "$(dirname "$0")/.."

export CLAUDE_USAGE_FIXTURE=tests/fixtures/claude-usage.json
export XDG_STATE_HOME=$(mktemp -d)
trap 'rm -rf "$XDG_STATE_HOME"' EXIT
# Fixed clock: 2h50m before the fixture's session reset.
export CLAUDE_USAGE_NOW=$(date -d 2026-10-09T19:19:59Z +%s)

fail=0
check() { # name expected actual
    if [[ $2 == "$3" ]]; then echo "ok   $1"; else echo "FAIL $1: expected [$2] got [$3]"; fail=1; fi
}

out=$(scripts/waybar-claude-usage.sh)
check "text shows session pct and eta" $' 7% · 2h50m' "$(jq -r .text <<<"$out")"
check "normal class under 60%" normal "$(jq -r '.class[0]' <<<"$out")"
check "tooltip has credits" 1 "$(jq -r '.tooltip | contains("Credits: $2.06 / $220.00") | if . then 1 else 0 end' <<<"$out")"
check "default profile is fast" 1 "$(jq -r '.tooltip | contains("Profile: fast (30s)") | if . then 1 else 0 end' <<<"$out")"

scripts/waybar-claude-usage.sh set med >/dev/null 2>&1
check "set med" 1 "$(scripts/waybar-claude-usage.sh | jq -r '.tooltip | contains("med (60s)") | if . then 1 else 0 end')"
scripts/waybar-claude-usage.sh cycle >/dev/null 2>&1
check "cycle med -> long" 1 "$(scripts/waybar-claude-usage.sh | jq -r '.tooltip | contains("long (300s)") | if . then 1 else 0 end')"
scripts/waybar-claude-usage.sh cycle >/dev/null 2>&1
check "cycle long -> fast" 1 "$(scripts/waybar-claude-usage.sh | jq -r '.tooltip | contains("fast (30s)") | if . then 1 else 0 end')"

exit $fail
