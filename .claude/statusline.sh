#!/bin/bash
# Claude Code statusLine - inspired by Starship config

input=$(cat)

# Parse JSON input from Claude Code
MODEL=$(echo "$input" | jq -r '.model.display_name // "claude"')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
LINES_ADDED=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
LINES_REMOVED=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
CWD=$(echo "$input" | jq -r '.cwd // ""')
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
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

# AI info (model name in orange)
OUTPUT+="  󰚩 $(printf '\033[38;5;214m%s\033[0m' "$MODEL")"

# Cost (format to 4 decimal places)
COST_FMT=$(printf "%.4f" "$COST")
OUTPUT+="  \$$COST_FMT"

# Lines changed (with colors - green for additions, red for deletions)
if [[ "$LINES_ADDED" != "0" || "$LINES_REMOVED" != "0" ]]; then
    OUTPUT+=$(printf "  \033[38;5;2m+%s\033[0m/\033[38;5;1m-%s\033[0m" "$LINES_ADDED" "$LINES_REMOVED")
fi

# Duration (format as minutes:seconds with timer icon in yellow) - LAST
DURATION_INT=$(printf "%.0f" "$DURATION")
MINUTES=$((DURATION_INT / 60))
SECONDS=$((DURATION_INT % 60))
OUTPUT+=$(printf "  \033[38;5;226m󰔚 %d:%02d\033[0m" "$MINUTES" "$SECONDS")

echo "$OUTPUT"
