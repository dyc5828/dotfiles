#!/bin/bash
# Claude Code statusLine - inspired by Starship config
#
# Layout: sections separated by | delimiters, each responsible for one concern.
#
#   Section 1 — Model & Context Window
#     "How is this conversation doing?"
#     Model name, context fill icon, usage percentage, 200k threshold diamond.
#     Tells you: what model you're on, how full the window is, and whether
#     you've crossed into large-context territory.
#
#   Section 2 — Location
#     "Where am I working?"
#     Working directory and git branch (or worktree indicator).
#     Tells you: which project and branch this session is operating in.
#
#   Section 3 — Impact
#     "What has changed?"
#     Lines added/removed.
#     Tells you: the footprint of changes made in this session.
#
#   Section 4 — Session Cost
#     "What has this session consumed?"
#     Dollar cost and wall-clock time.
#     Tells you: the real-world resources spent on this conversation.
#
# Future candidates for data points within existing sections:
#   - Cumulative input/output tokens (Section 4, if token-level cost awareness proves useful)
#   - Cache efficiency (Section 1, if context reuse becomes a tuning concern)

input=$(cat)

# Debug: save input to file to see what Claude sends
# echo "$input" > /tmp/claude_statusline_debug.json

# Parse JSON input from Claude Code
MODEL_RAW=$(echo "$input" | jq -r '.model.display_name // "claude"')
# Shorten model name: "Claude Opus 4.6 (1M context)" → "Opus 4.6"
MODEL=$(echo "$MODEL_RAW" | sed -E 's/^Claude //' | sed -E 's/ \([^)]*\)$//' | sed -E 's/^ +//;s/ +$//')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
LINES_ADDED=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
LINES_REMOVED=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
CWD=$(echo "$input" | jq -r '.cwd // ""')
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')

# Context window info
CTX_USED_PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
EXCEEDS_200K=$(echo "$input" | jq -r '.exceeds_200k_tokens // false')
DURATION=$((DURATION_MS / 1000))

# Get git branch if in a repo
GIT_BRANCH=""
IS_WORKTREE=""
if git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    GIT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --exact-match 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    # Check if in a worktree (git dir contains "worktrees")
    GIT_DIR=$(git rev-parse --git-dir 2>/dev/null)
    if [[ "$GIT_DIR" == *"/worktrees/"* ]]; then
        IS_WORKTREE="true"
    fi
fi

# Colors
SEP_COLOR="38;5;240"      # dim gray for separators
MODEL_COLOR="38;5;214"    # orange
DIR_COLOR="38;5;37"       # teal
BRANCH_COLOR="38;5;213"   # pink
WORKTREE_COLOR="38;5;114" # green
ADD_COLOR="38;5;2"        # green
DEL_COLOR="38;5;1"        # red
TIME_COLOR="38;5;226"     # yellow

# Context icon + color — tuned for 1M context window
#
# Design intent:
#   Green  (< 20%, ~200k tokens): plenty of room, no concerns
#   Yellow (20-60%, ~200k-600k):  normal usage, working comfortably
#   Orange (60-85%, ~600k-850k):  compaction is on the horizon, start thinking about it
#   Red    (85%+, ~850k+):       compaction imminent
#
# Icons (○ ◔ ◑ ◕ ●) are aligned with color boundaries so the visual
# fill level and color shift feel coherent together.

# Icon: fill level tracks the color zones
if [[ "$CTX_USED_PCT" -lt 20 ]]; then
    CTX_ICON="○"
elif [[ "$CTX_USED_PCT" -lt 40 ]]; then
    CTX_ICON="◔"
elif [[ "$CTX_USED_PCT" -lt 60 ]]; then
    CTX_ICON="◑"
elif [[ "$CTX_USED_PCT" -lt 85 ]]; then
    CTX_ICON="◕"
else
    CTX_ICON="●"
fi

# Color: green → yellow → orange → red
if [[ "$CTX_USED_PCT" -lt 20 ]]; then
    CTX_COLOR="38;5;2"    # green — plenty of room
elif [[ "$CTX_USED_PCT" -lt 60 ]]; then
    CTX_COLOR="38;5;226"  # yellow — normal usage
elif [[ "$CTX_USED_PCT" -lt 85 ]]; then
    CTX_COLOR="38;5;214"  # orange — compaction on the horizon
else
    CTX_COLOR="38;5;196"  # red — compaction imminent
fi

# ── Build output ──────────────────────────────────────────────────────
OUTPUT=""

# Section 1: Model & Context Window — "How is this conversation doing?"
# ◆ diamond appears when session exceeds 200k tokens (Claude-provided flag)
CTX_200K=""
if [[ "$EXCEEDS_200K" == "true" ]]; then
    CTX_200K=" ◆"
fi
OUTPUT+=$(printf "\033[${MODEL_COLOR}m%s\033[0m \033[${CTX_COLOR}m%s %s%%%s\033[0m" "$MODEL" "$CTX_ICON" "$CTX_USED_PCT" "$CTX_200K")

# Section 2: Location — "Where am I working?"
if [[ -n "$CWD" ]]; then
    CWD_SHORT=$(basename "$CWD")
    OUTPUT+=$(printf " \033[${SEP_COLOR}m|\033[0m \033[${DIR_COLOR}m▸ ../%s\033[0m" "$CWD_SHORT")
fi
if [[ -n "$GIT_BRANCH" ]]; then
    if [[ -n "$IS_WORKTREE" ]]; then
        OUTPUT+=$(printf " \033[${SEP_COLOR}m|\033[0m \033[${WORKTREE_COLOR}m◈ %s\033[0m" "$GIT_BRANCH")
    else
        OUTPUT+=$(printf " \033[${SEP_COLOR}m|\033[0m \033[${BRANCH_COLOR}m⎇ %s\033[0m" "$GIT_BRANCH")
    fi
fi

# Section 3: Impact — "What has changed?"
if [[ "$LINES_ADDED" != "0" || "$LINES_REMOVED" != "0" ]]; then
    OUTPUT+=$(printf " \033[${SEP_COLOR}m|\033[0m \033[${ADD_COLOR}m± %s\033[0m/\033[${DEL_COLOR}m%s\033[0m" "$LINES_ADDED" "$LINES_REMOVED")
fi

# Section 4: Session Cost — "What has this session consumed?"
COST_FMT=$(printf "%.2f" "$COST")
DURATION_INT=$(printf "%.0f" "$DURATION")
HOURS=$((DURATION_INT / 3600))
MINUTES=$(((DURATION_INT % 3600) / 60))
OUTPUT+=$(printf " \033[${SEP_COLOR}m|\033[0m \$%s·\033[${TIME_COLOR}m%d:%02d\033[0m" "$COST_FMT" "$HOURS" "$MINUTES")

echo "$OUTPUT"
