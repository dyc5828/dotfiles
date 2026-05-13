#!/usr/bin/env bash
# Output a short label for the current AWS auth state, for the
# [custom.aws_sso] module in ~/.config/starship.toml.
#
# Precedence (highest priority first — reflects what the shell can DO):
#   $AWS_VAULT set                              → "vault:$AWS_VAULT (<remaining>)"
#   $AWS_PROFILE set + SSO valid for it         → "$AWS_PROFILE (<remaining>)"
#   Any SSO session valid, $AWS_PROFILE unset   → "homebot (<remaining>)"
#   None of the above                           → exit 1 (hide module)
#
# Avoids spawning aws CLI so it runs fast enough for a prompt hook.

set -euo pipefail

config="${AWS_CONFIG_FILE:-$HOME/.aws/config}"
cache_dir="$HOME/.aws/sso/cache"

# --- Time helpers ---
# Convert seconds → "1h8m" / "23m" / "45s"
fmt_duration() {
  local s=$1
  (( s <= 0 )) && { echo "expired"; return; }
  local h=$((s/3600)) m=$(((s%3600)/60))
  if (( h > 0 ));   then echo "${h}h${m}m"
  elif (( m > 0 )); then echo "${m}m"
  else                   echo "${s}s"
  fi
}

# Seconds until $1 (an ISO-8601 timestamp), or empty on parse error.
seconds_until() {
  local target_epoch now_epoch
  target_epoch=$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$1" "+%s" 2>/dev/null) || return 1
  now_epoch=$(date -u "+%s")
  echo $(( target_epoch - now_epoch ))
}

# Earliest expiresAt across all currently-valid SSO cache entries for a given start_url.
# Outputs seconds remaining, or empty.
sso_seconds_remaining_for_url() {
  local url=$1
  local secs
  secs=$(jq -r --arg u "$url" '
    select(.startUrl == $u and .expiresAt and (.expiresAt | fromdateiso8601) > now)
    | .expiresAt
  ' "$cache_dir"/*.json 2>/dev/null | while read -r ts; do
    seconds_until "$ts"
  done | sort -n | head -n1)
  echo "$secs"
}

# --- 1. aws-vault subshell takes precedence ---
if [[ -n "${AWS_VAULT:-}" ]]; then
  label="vault:${AWS_VAULT}"
  # aws-vault uses AWS_CREDENTIAL_EXPIRATION (newer) or AWS_SESSION_EXPIRATION (older).
  expiry="${AWS_CREDENTIAL_EXPIRATION:-${AWS_SESSION_EXPIRATION:-}}"
  if [[ -n "$expiry" ]]; then
    secs=$(seconds_until "$expiry" 2>/dev/null || echo "")
    [[ -n "$secs" ]] && label="${label}·$(fmt_duration "$secs")"
  fi
  echo "$label"
  exit 0
fi

# --- 2. Need SSO config + cache for the rest ---
[[ -f "$config" && -d "$cache_dir" ]] || exit 1

portal_nickname() {
  case "$1" in
    https://d-906767f97d.awsapps.com/start) echo "homebot" ;;
    *) echo "sso" ;;
  esac
}

valid_urls=$(jq -r '
  select(.startUrl and .expiresAt and (.expiresAt | fromdateiso8601) > now)
  | .startUrl
' "$cache_dir"/*.json 2>/dev/null | sort -u)
[[ -z "$valid_urls" ]] && exit 1

profile_start_url() {
  awk -v target="$1" '
    /^\[profile / { sub(/^\[profile /, ""); sub(/\][[:space:]]*$/, ""); profile=$0; next }
    /^\[/        { profile="" }
    profile == target && /^[[:space:]]*sso_start_url[[:space:]]*=/ {
      sub(/^[[:space:]]*sso_start_url[[:space:]]*=[[:space:]]*/, "")
      print; exit
    }
  ' "$config"
}

if [[ -n "${AWS_PROFILE:-}" ]]; then
  url=$(profile_start_url "$AWS_PROFILE")
  [[ -z "$url" ]] && exit 1
  grep -Fxq "$url" <<<"$valid_urls" || exit 1
  secs=$(sso_seconds_remaining_for_url "$url")
  if [[ -n "$secs" ]]; then
    echo "${AWS_PROFILE}·$(fmt_duration "$secs")"
  else
    echo "$AWS_PROFILE"
  fi
  exit 0
fi

# No AWS_PROFILE — show the nickname of the first valid portal.
first_url=$(head -n1 <<<"$valid_urls")
secs=$(sso_seconds_remaining_for_url "$first_url")
nick=$(portal_nickname "$first_url")
if [[ -n "$secs" ]]; then
  echo "${nick}·$(fmt_duration "$secs")"
else
  echo "$nick"
fi
