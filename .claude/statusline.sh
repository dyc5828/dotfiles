#!/bin/bash
# Claude Code statusLine - inspired by Starship config

input=$(cat)

# Debug: save input to file to see what Claude sends
# echo "$input" > /tmp/claude_statusline_debug.json

# Parse JSON input from Claude Code
MODEL=$(echo "$input" | jq -r '.model.display_name // "claude"')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
LINES_ADDED=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
LINES_REMOVED=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
CWD=$(echo "$input" | jq -r '.cwd // ""')
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')

# Context window info
CTX_USED_PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
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

# Context icon (5 levels: ○ ◔ ◑ ◕ ●)
if [[ "$CTX_USED_PCT" -lt 20 ]]; then
    CTX_ICON="○"
elif [[ "$CTX_USED_PCT" -lt 40 ]]; then
    CTX_ICON="◔"
elif [[ "$CTX_USED_PCT" -lt 60 ]]; then
    CTX_ICON="◑"
elif [[ "$CTX_USED_PCT" -lt 80 ]]; then
    CTX_ICON="◕"
else
    CTX_ICON="●"
fi

# Context color: green <40%, yellow 40-60%, orange 60-75%, red >=75%
if [[ "$CTX_USED_PCT" -lt 40 ]]; then
    CTX_COLOR="38;5;2"    # green
elif [[ "$CTX_USED_PCT" -lt 60 ]]; then
    CTX_COLOR="38;5;226"  # yellow
elif [[ "$CTX_USED_PCT" -lt 75 ]]; then
    CTX_COLOR="38;5;214"  # orange
else
    CTX_COLOR="38;5;196"  # red (autocompact imminent)
fi

# Build progress bar (8 chars wide)
BAR_WIDTH=8
FILLED=$((CTX_USED_PCT * BAR_WIDTH / 100))
EMPTY=$((BAR_WIDTH - FILLED))
BAR_FILLED=""
BAR_EMPTY=""
for ((i=0; i<FILLED; i++)); do BAR_FILLED+="="; done
for ((i=0; i<EMPTY; i++)); do BAR_EMPTY+=" "; done

# Build output
OUTPUT=""

# 1. Model with context icon (no separator after)
OUTPUT+=$(printf "\033[${CTX_COLOR}m%s\033[0m \033[${MODEL_COLOR}m%s\033[0m" "$CTX_ICON" "$MODEL")

# 2. Context bar and percentage
OUTPUT+=$(printf " [\033[${CTX_COLOR}m%s\033[0m%s] \033[${CTX_COLOR}m%s%%\033[0m" "$BAR_FILLED" "$BAR_EMPTY" "$CTX_USED_PCT")

# 3. Directory (teal)
if [[ -n "$CWD" ]]; then
    CWD_SHORT=$(basename "$CWD")
    OUTPUT+=$(printf " \033[${SEP_COLOR}m|\033[0m \033[${DIR_COLOR}m▸ ../%s\033[0m" "$CWD_SHORT")
fi

# 4. Git branch (pink) or worktree (green)
if [[ -n "$GIT_BRANCH" ]]; then
    if [[ -n "$IS_WORKTREE" ]]; then
        OUTPUT+=$(printf " \033[${SEP_COLOR}m|\033[0m \033[${WORKTREE_COLOR}m◈ %s\033[0m" "$GIT_BRANCH")
    else
        OUTPUT+=$(printf " \033[${SEP_COLOR}m|\033[0m \033[${BRANCH_COLOR}m⎇ %s\033[0m" "$GIT_BRANCH")
    fi
fi

# 5. Lines changed (green/red with icon)
if [[ "$LINES_ADDED" != "0" || "$LINES_REMOVED" != "0" ]]; then
    OUTPUT+=$(printf " \033[${SEP_COLOR}m|\033[0m \033[${ADD_COLOR}m± %s\033[0m/\033[${DEL_COLOR}m%s\033[0m" "$LINES_ADDED" "$LINES_REMOVED")
fi

# 6. Cost and duration (at the end)
COST_FMT=$(printf "%.2f" "$COST")
DURATION_INT=$(printf "%.0f" "$DURATION")
HOURS=$((DURATION_INT / 3600))
MINUTES=$(((DURATION_INT % 3600) / 60))
OUTPUT+=$(printf " \033[${SEP_COLOR}m|\033[0m \$%s·\033[${TIME_COLOR}m%d:%02d\033[0m" "$COST_FMT" "$HOURS" "$MINUTES")

echo "$OUTPUT"
