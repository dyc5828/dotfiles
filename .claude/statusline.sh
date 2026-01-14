#!/bin/bash
# Claude Code statusLine - inspired by Starship config

input=$(cat)

# Debug: save input to file to see what Claude sends
echo "$input" > /tmp/claude_statusline_debug.json

# Parse JSON input from Claude Code
MODEL=$(echo "$input" | jq -r '.model.display_name // "claude"')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
LINES_ADDED=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
LINES_REMOVED=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
CWD=$(echo "$input" | jq -r '.cwd // ""')
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')

# Context window and token info
TOTAL_INPUT=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
TOTAL_OUTPUT=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
CTX_USED_PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
DURATION=$((DURATION_MS / 1000))

# Get username
USER=$(whoami)

# Get git branch if in a repo
GIT_BRANCH=""
if git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    GIT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --exact-match 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
fi

# Detect language versions from current directory
NODE_VER=""
if [[ -f "package.json" ]] && command -v node &>/dev/null; then
    NODE_VER=$(node -v 2>/dev/null | sed 's/v//')
fi

RUBY_VER=""
if [[ -f "Gemfile" ]] && command -v ruby &>/dev/null; then
    RUBY_VER=$(ruby -v 2>/dev/null | awk '{print $2}')
fi

PYTHON_VER=""
if [[ -f "requirements.txt" || -f "pyproject.toml" || -f "setup.py" ]] && command -v python3 &>/dev/null; then
    PYTHON_VER=$(python3 --version 2>/dev/null | awk '{print $2}')
fi

# Build output matching Starship style
OUTPUT=""

# User (yellow)
OUTPUT+=" $(printf '\033[38;5;226m%s\033[0m' "$USER")"

# Git branch (pink)
if [[ -n "$GIT_BRANCH" ]]; then
    OUTPUT+="  $(printf '\033[38;5;213m%s\033[0m' " $GIT_BRANCH")"
fi

# Language versions
if [[ -n "$NODE_VER" ]]; then
    OUTPUT+="   $NODE_VER"
fi
if [[ -n "$RUBY_VER" ]]; then
    OUTPUT+="   $RUBY_VER"
fi
if [[ -n "$PYTHON_VER" ]]; then
    OUTPUT+="   $PYTHON_VER"
fi

# AI info (model icon and name in orange)
OUTPUT+=$(printf "  \033[38;5;214m󰚩 %s\033[0m" "$MODEL")

# Context: percentage first, then input/output tokens (color-coded)
if [[ "$TOTAL_INPUT" -gt 0 || "$TOTAL_OUTPUT" -gt 0 ]]; then
    # Format tokens with K suffix
    if [[ "$TOTAL_INPUT" -ge 1000 ]]; then
        IN_FMT=$(echo "scale=0; $TOTAL_INPUT / 1000" | bc)K
    else
        IN_FMT="$TOTAL_INPUT"
    fi
    if [[ "$TOTAL_OUTPUT" -ge 1000 ]]; then
        OUT_FMT=$(echo "scale=0; $TOTAL_OUTPUT / 1000" | bc)K
    else
        OUT_FMT="$TOTAL_OUTPUT"
    fi
    # Dynamic progress icon based on usage (8 levels)
    if [[ "$CTX_USED_PCT" -lt 12 ]]; then
        CTX_ICON="󰪞"
    elif [[ "$CTX_USED_PCT" -lt 25 ]]; then
        CTX_ICON="󰪟"
    elif [[ "$CTX_USED_PCT" -lt 37 ]]; then
        CTX_ICON="󰪠"
    elif [[ "$CTX_USED_PCT" -lt 50 ]]; then
        CTX_ICON="󰪡"
    elif [[ "$CTX_USED_PCT" -lt 62 ]]; then
        CTX_ICON="󰪢"
    elif [[ "$CTX_USED_PCT" -lt 75 ]]; then
        CTX_ICON="󰪣"
    elif [[ "$CTX_USED_PCT" -lt 87 ]]; then
        CTX_ICON="󰪤"
    else
        CTX_ICON="󰪥"
    fi
    # Icon color: green <40%, yellow 40-60%, orange 60-75%, red >=75%
    if [[ "$CTX_USED_PCT" -lt 40 ]]; then
        ICON_COLOR="38;5;2"    # green
    elif [[ "$CTX_USED_PCT" -lt 60 ]]; then
        ICON_COLOR="38;5;226"  # yellow
    elif [[ "$CTX_USED_PCT" -lt 75 ]]; then
        ICON_COLOR="38;5;214"  # orange
    else
        ICON_COLOR="38;5;196"  # red (autocompact imminent)
    fi
    # Icon + percentage (same color), input (cyan) / output (magenta)
    OUTPUT+=$(printf "  \033[${ICON_COLOR}m%s %s%%\033[0m" "$CTX_ICON" "$CTX_USED_PCT")
    OUTPUT+=$(printf " \033[38;5;81m%s\033[0m" "$IN_FMT")
    OUTPUT+=$(printf "/\033[38;5;177m%s\033[0m" "$OUT_FMT")
fi

# Cost (format to 4 decimal places)
COST_FMT=$(printf "%.4f" "$COST")
OUTPUT+="  \$$COST_FMT"

# Lines changed (with colors - green for additions, red for deletions)
if [[ "$LINES_ADDED" != "0" || "$LINES_REMOVED" != "0" ]]; then
    OUTPUT+=$(printf "  \033[38;5;2m󰦒 %s\033[0m/\033[38;5;1m%s\033[0m" "$LINES_ADDED" "$LINES_REMOVED")
fi

# Duration (format as minutes:seconds with timer icon in yellow) - LAST
DURATION_INT=$(printf "%.0f" "$DURATION")
MINUTES=$((DURATION_INT / 60))
SECONDS=$((DURATION_INT % 60))
OUTPUT+=$(printf "  \033[38;5;226m󰔛 %d:%02d\033[0m" "$MINUTES" "$SECONDS")

echo "$OUTPUT"
