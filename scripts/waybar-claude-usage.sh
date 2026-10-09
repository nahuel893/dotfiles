#!/usr/bin/env bash
# Waybar pill with Claude usage (session 5h window; weekly + credits in tooltip).
#
# Usage:
#   waybar-claude-usage.sh            print waybar JSON (called by waybar every few seconds)
#   waybar-claude-usage.sh cycle      switch profile fast -> med -> long -> fast
#   waybar-claude-usage.sh set <p>    set profile (fast|med|long)
#   waybar-claude-usage.sh refresh    drop the cache and refetch now
#
# Waybar ticks often (cheap); the API is only hit when the cache is older than
# the active profile's TTL: fast=30s (default), med=60s, long=300s.
#
# Env overrides (used by tests): CLAUDE_CREDENTIALS, CLAUDE_USAGE_FIXTURE, CLAUDE_USAGE_NOW.
set -euo pipefail

SIGNAL=8 # must match "signal" in the waybar module
CREDS="${CLAUDE_CREDENTIALS:-$HOME/.claude/.credentials.json}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/claude-usage"
PROFILE_FILE="$STATE_DIR/profile"
CACHE="${XDG_RUNTIME_DIR:-/tmp}/claude-usage.json"
LOCK="${XDG_RUNTIME_DIR:-/tmp}/claude-usage.lock"
URL="https://api.anthropic.com/api/oauth/usage"

profile() {
    local p=fast
    [[ -r $PROFILE_FILE ]] && p=$(<"$PROFILE_FILE")
    case $p in fast | med | long) echo "$p" ;; *) echo fast ;; esac
}

ttl() {
    case $1 in fast) echo 30 ;; med) echo 60 ;; long) echo 300 ;; esac
}

set_profile() {
    mkdir -p "$STATE_DIR"
    echo "$1" >"$PROFILE_FILE"
    command -v notify-send >/dev/null && notify-send -t 1500 "Claude usage" "profile: $1 ($(ttl "$1")s)" || true
    pkill -RTMIN+"$SIGNAL" waybar || true
}

fetch() {
    local token tmp http
    token=$(jq -er '.claudeAiOauth.accessToken' "$CREDS") || return 1
    tmp=$(mktemp)
    # Token goes through stdin so it never shows up in `ps`.
    http=$(printf 'header = "Authorization: Bearer %s"\nheader = "anthropic-beta: oauth-2025-04-20"\n' "$token" |
        curl -s -m 10 -K - -o "$tmp" -w '%{http_code}' "$URL") || { rm -f "$tmp"; return 1; }
    if [[ $http == 200 ]] && jq -e '.five_hour' "$tmp" >/dev/null 2>&1; then
        mv "$tmp" "$CACHE"
    else
        rm -f "$tmp"
        return 1
    fi
}

cache_age() {
    [[ -f $CACHE ]] || { echo 999999; return; }
    echo $(($(date +%s) - $(stat -c %Y "$CACHE")))
}

render() {
    local data=$1 stale=$2 prof=$3
    jq -c --argjson now "${CLAUDE_USAGE_NOW:-$(date +%s)}" --arg stale "$stale" --arg prof "$prof" --arg ttl "$(ttl "$prof")" '
        def ts: sub("\\.[0-9]+"; "") | sub("\\+00:00$"; "Z") | fromdateiso8601;
        def eta($t):
            ($t | ts) - $now as $d
            | if $d <= 0 then "now"
              elif $d >= 86400 then "\($d / 86400 | floor)d\(($d % 86400) / 3600 | floor)h"
              elif $d >= 3600 then "\($d / 3600 | floor)h\(($d % 3600) / 60 | floor)m"
              else "\($d / 60 | floor)m" end;
        def cls($p): if $p >= 85 then "critical" elif $p >= 60 then "warning" else "normal" end;
        def usd($m):
            ($m.amount_minor / pow(10; $m.exponent) * 100 | round) as $c
            | "$\($c / 100 | floor).\("0\($c % 100)" | .[-2:])";
        (.five_hour.utilization | round) as $s
        | (.seven_day.utilization // 0 | round) as $w
        | {
            text: " \($s)% · \(eta(.five_hour.resets_at))\(if $stale == "1" then " !" else "" end)",
            tooltip: ([
                "Session (5h): \($s)%  resets in \(eta(.five_hour.resets_at))",
                "Weekly: \($w)%  resets in \(eta(.seven_day.resets_at))",
                (if .spend then
                    "Credits: \(usd(.spend.used)) / \(usd(.spend.limit))"
                    + (if .spend.enabled then "" else " (extra usage off)" end)
                 else empty end),
                "",
                "Profile: \($prof) (\($ttl)s) - click to switch, right-click to refresh"
                + (if $stale == "1" then "\nLast fetch failed: showing cached data" else "" end)
            ] | join("\n")),
            class: ([cls($s)] + (if $stale == "1" then ["stale"] else [] end)),
            percentage: $s
          }' <<<"$data"
}

main() {
    local prof age data stale=0
    prof=$(profile)

    if [[ -n ${CLAUDE_USAGE_FIXTURE:-} ]]; then
        render "$(<"$CLAUDE_USAGE_FIXTURE")" 0 "$prof"
        return
    fi

    age=$(cache_age)
    if ((age >= $(ttl "$prof"))); then
        exec 9>"$LOCK"
        if flock -n 9; then
            fetch || stale=1
        fi
    fi

    if [[ -f $CACHE ]]; then
        data=$(<"$CACHE")
        # A cache older than twice the TTL means fetches are failing.
        (($(cache_age) >= 2 * $(ttl "$prof"))) && stale=1
        render "$data" "$stale" "$prof"
    else
        jq -nc '{text: " --", tooltip: "Claude usage unavailable (not logged in or offline)", class: ["error"]}'
    fi
}

case "${1:-}" in
    cycle)
        case $(profile) in fast) set_profile med ;; med) set_profile long ;; *) set_profile fast ;; esac
        ;;
    set)
        case ${2:-} in fast | med | long) set_profile "$2" ;; *) echo "usage: $0 set fast|med|long" >&2; exit 2 ;; esac
        ;;
    refresh)
        rm -f "$CACHE"
        pkill -RTMIN+"$SIGNAL" waybar || true
        ;;
    "") main ;;
    *) echo "usage: $0 [cycle|set <profile>|refresh]" >&2; exit 2 ;;
esac
