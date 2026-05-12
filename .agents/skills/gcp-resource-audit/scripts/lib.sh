#!/usr/bin/env bash
# Shared helpers for gcp-resource-audit scripts.
# Source this file from any audit_*.sh script:
#   source "$SCRIPT_DIR/lib.sh"

# Disable interactive prompts globally so gcloud fails fast rather than hanging
# on stdin when it would otherwise ask for region, project, or confirmation.
export CLOUDSDK_CORE_DISABLE_PROMPTS=1

# Dependency checking is the caller's responsibility — see the Prerequisites
# section in SKILL.md. The scripts assume gcloud, jq, bq, and column are on
# PATH; if any is missing, gcloud/jq/bq/column will surface their own errors
# and the audit output will be unreliable. The skill instructions tell the
# agent to verify the environment before invoking these scripts.

# is_permission_error <stderr_file>
# Returns 0 if the given stderr file contains a recognized permission-denied
# phrase from gcloud or bq. Centralizing this lets audit scripts that inline
# their own stderr capture (e.g. for custom output rendering) stay in sync
# with run_gcloud's classification.
is_permission_error() {
  grep -qiE "permission denied|does not have permission|caller does not have|insufficient authentication scopes|forbidden|access denied|unauthorized|permission_denied" "$1"
}

# is_api_not_enabled_error <stderr_file>
# Companion to is_permission_error for the API-disabled case.
is_api_not_enabled_error() {
  grep -qiE "api .* not enabled|has not been used|api is disabled" "$1"
}

# run_gcloud <gcloud command...>
# Captures stdout and stderr separately, emits one of:
#   <output>          — when the command produced rows
#   (none)            — when the command succeeded with no rows
#   (no access)       — when stderr indicates permission denied
#   (API not enabled) — when stderr indicates the API is off
#   (error: ...)      — any other failure, with first line of stderr
run_gcloud() {
  local stderr_file output rc
  stderr_file=$(mktemp)
  output=$("$@" 2>"$stderr_file")
  rc=$?

  if [[ $rc -eq 0 ]]; then
    if [[ -z "$(echo "$output" | tr -d '[:space:]')" ]]; then
      echo "(none)"
    else
      echo "$output"
    fi
  elif is_permission_error "$stderr_file"; then
    echo "(no access)"
  elif is_api_not_enabled_error "$stderr_file"; then
    echo "(API not enabled)"
  else
    echo "(error: $(head -n1 "$stderr_file"))"
  fi

  rm -f "$stderr_file"
}

# has_api <api-name>
# Returns 0 if the API is enabled on the project. Requires ENABLED_APIS to be
# set by the caller (cache once per project to avoid repeated round trips).
has_api() {
  grep -qx "$1" <<<"${ENABLED_APIS:-}"
}

# section <heading>
section() { printf "\n### %s\n" "$1"; }
