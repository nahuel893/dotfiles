#!/usr/bin/env bash
# Claude Code status line — model, workspace/git, context usage, cost, session meta.
# Reads the JSON documented at https://code.claude.com/docs/en/statusline via stdin.
export LC_NUMERIC=C # printf %f parses the decimal point per-locale; force '.' regardless of system locale
input=$(cat)

jqr() { jq -r "$1 // empty" <<<"$input" 2>/dev/null; }

# openskin's status panel redraws this line beside the transcript: keep each session's latest
# input for it. Where the panel is docked it marks the session, and the line here keeps what is
# read at a glance; the panel runs this script with OPENSKIN_PANEL=1 to get the rest.
SESSION_ID=$(jqr '.session_id')
DOCKED=""
if [ -n "$SESSION_ID" ]; then
  OPENSKIN=~/.cache/openskin
  mkdir -p "$OPENSKIN/sessions" &&
    printf '%s' "$input" >"$OPENSKIN/sessions/$SESSION_ID.json.tmp" &&
    mv -f "$OPENSKIN/sessions/$SESSION_ID.json.tmp" "$OPENSKIN/sessions/$SESSION_ID.json"
  [ -z "$OPENSKIN_PANEL" ] && [ -e "$OPENSKIN/docked/$SESSION_ID" ] && DOCKED=1
fi

MODEL=$(jqr '.model.display_name')
DIR=$(jqr '.workspace.current_dir // .cwd')
DIRNAME="${DIR##*/}"
STYLE=$(jqr '.output_style.name')
EFFORT=$(jqr '.effort.level')
FAST=$(jqr '.fast_mode')
VERSION=$(jqr '.version')
AGENT=$(jqr '.agent.name')
WORKTREE=$(jqr '.worktree.name')
REPO_OWNER=$(jqr '.workspace.repo.owner')
REPO_NAME=$(jqr '.workspace.repo.name')
PR_NUM=$(jqr '.pr.number')
PR_STATE=$(jqr '.pr.review_state')
VIM_MODE=$(jqr '.vim.mode')

COST=$(jqr '.cost.total_cost_usd')
DUR_MS=$(jqr '.cost.total_duration_ms')
API_MS=$(jqr '.cost.total_api_duration_ms')
LINES_ADD=$(jqr '.cost.total_lines_added')
LINES_DEL=$(jqr '.cost.total_lines_removed')

PCT=$(jqr '.context_window.used_percentage')
IN_TOK=$(jqr '.context_window.total_input_tokens')
CTX_SIZE=$(jqr '.context_window.context_window_size')

# The 5-hour and weekly windows are left to better-claude's sub-meter (and openskin's panel).

CYAN='\033[36m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; DIM='\033[2m'; RESET='\033[0m'

# --- vim mode: green while typing, yellow otherwise ---
VIM_SEG=""
if [ -n "$VIM_MODE" ]; then
    VIM_COLOR="$YELLOW"; [ "$VIM_MODE" = "INSERT" ] && VIM_COLOR="$GREEN"
    VIM_SEG="${VIM_COLOR}⌨ ${VIM_MODE}${RESET}"
fi

# join_parts drops empty args so optional segments never leave a dangling " | "
join_parts() {
    local out="" p
    for p in "$@"; do
        [ -n "$p" ] && out="${out}${out:+ | }${p}"
    done
    printf '%s' "$out"
}

# --- git branch + dirty state ---
GIT_SEG=""
if git -C "$DIR" rev-parse --git-dir >/dev/null 2>&1; then
    BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
    [ -z "$BRANCH" ] && BRANCH=$(git -C "$DIR" rev-parse --short HEAD 2>/dev/null)
    STAGED=$(git -C "$DIR" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    MODIFIED=$(git -C "$DIR" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
    UNTRACKED=$(git -C "$DIR" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    DIRTY=""
    [ "$STAGED" -gt 0 ] && DIRTY="${DIRTY}${GREEN}+${STAGED}${RESET}"
    [ "$MODIFIED" -gt 0 ] && DIRTY="${DIRTY}${YELLOW}~${MODIFIED}${RESET}"
    [ "$UNTRACKED" -gt 0 ] && DIRTY="${DIRTY}${DIM}?${UNTRACKED}${RESET}"
    GIT_SEG="🌿 ${BRANCH}${DIRTY:+ $DIRTY}"
fi

# --- repo / PR / worktree / subagent ---
REPO_SEG=""
[ -n "$REPO_OWNER" ] && REPO_SEG="🔗 ${REPO_OWNER}/${REPO_NAME}"
[ -n "$PR_NUM" ] && REPO_SEG="${REPO_SEG} #${PR_NUM}${PR_STATE:+ (${PR_STATE})}"
WORKTREE_SEG=""
[ -n "$WORKTREE" ] && WORKTREE_SEG="🌳 ${WORKTREE}"
AGENT_SEG=""
[ -n "$AGENT" ] && AGENT_SEG="🤖 ${AGENT}"

MODEL_SEG="${CYAN}[${MODEL}]${RESET}"
DIR_SEG="📁 ${DIRNAME}"

# --- context usage bar ---
PCT_INT=${PCT%%.*}
[ -z "$PCT_INT" ] && PCT_INT=0
BAR_WIDTH=10
FILLED=$((PCT_INT * BAR_WIDTH / 100))
EMPTY=$((BAR_WIDTH - FILLED))
BAR=""
[ "$FILLED" -gt 0 ] && printf -v FILL "%${FILLED}s" && BAR="${FILL// /█}"
[ "$EMPTY" -gt 0 ] && printf -v PAD "%${EMPTY}s" && BAR="${BAR}${PAD// /░}"
if [ "$PCT_INT" -ge 90 ]; then BAR_COLOR="$RED"
elif [ "$PCT_INT" -ge 70 ]; then BAR_COLOR="$YELLOW"
else BAR_COLOR="$GREEN"; fi

TOK_SEG=""
[ -n "$IN_TOK" ] && TOK_SEG=" (${IN_TOK}/${CTX_SIZE})"
CTX_SEG="${BAR_COLOR}${BAR}${RESET} ${PCT_INT}%${TOK_SEG}"

COST_FMT='$0.00'
[ -n "$COST" ] && COST_FMT=$(printf '$%.2f' "$COST")
COST_SEG="${YELLOW}${COST_FMT}${RESET}"

DUR_SEG=""
if [ -n "$DUR_MS" ]; then
    DUR_SEC=$((DUR_MS / 1000)); MINS=$((DUR_SEC / 60)); SECS=$((DUR_SEC % 60))
    DUR_SEG="⏱ ${MINS}m${SECS}s"
    if [ -n "$API_MS" ]; then
        API_SEC=$((API_MS / 1000)); API_MINS=$((API_SEC / 60)); API_SECS=$((API_SEC % 60))
        DUR_SEG="${DUR_SEG} (api ${API_MINS}m${API_SECS}s)"
    fi
fi

LINES_SEG=""
if [ -n "$LINES_ADD" ] || [ -n "$LINES_DEL" ]; then
    LINES_SEG="${GREEN}+${LINES_ADD:-0}${RESET}/${RED}-${LINES_DEL:-0}${RESET}"
fi

EFFORT_SEG=""
[ -n "$EFFORT" ] && EFFORT_SEG="🎚 ${EFFORT}"
STYLE_SEG=""
[ -n "$STYLE" ] && STYLE_SEG="🎨 ${STYLE}"
FAST_SEG=""
[ "$FAST" = "true" ] && FAST_SEG="⚡fast"
VERSION_SEG=""
[ -n "$VERSION" ] && VERSION_SEG="${DIM}v${VERSION}${RESET}"

# Docked: one line under the prompt with what is read at a glance; the panel draws the rest
# (its Status card has the folder, the branch and the changes).
if [ -n "$DOCKED" ]; then
    echo -e "$(join_parts "$MODEL_SEG" "$VIM_SEG" "$COST_SEG" "$DUR_SEG" "$EFFORT_SEG" "$STYLE_SEG")"
    exit 0
fi

# The panel: whatever the docked line leaves out (its context bar gives way to the Context section).
if [ -n "$OPENSKIN_PANEL" ]; then
    PANEL_LINE=$(join_parts "$REPO_SEG" "$WORKTREE_SEG" "$AGENT_SEG" "$FAST_SEG" "$VERSION_SEG")
    [ -n "$PANEL_LINE" ] && echo -e "$PANEL_LINE"
    exit 0
fi

# Undocked: the whole status line.
echo -e "$(join_parts "$MODEL_SEG $DIR_SEG" "$GIT_SEG" "$REPO_SEG" "$WORKTREE_SEG" "$AGENT_SEG")"
echo -e "$(join_parts "$CTX_SEG" "$COST_SEG" "$DUR_SEG" "$LINES_SEG")"
LINE3=$(join_parts "$EFFORT_SEG" "$STYLE_SEG" "$FAST_SEG" "$VIM_SEG" "$VERSION_SEG")
[ -n "$LINE3" ] && echo -e "$LINE3"
exit 0
