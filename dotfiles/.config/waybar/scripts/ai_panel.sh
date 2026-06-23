#!/usr/bin/env bash

set -euo pipefail

# Waybar often launches with a minimal PATH (no interactive shell init).
# Make sure common user install locations are available.
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

timezone="${TZ:-Europe/Oslo}"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
cache_file="$cache_dir/ai-panel.json"
# Waybar calls this every 60s; cache shorter than that so the UI updates per tick.
cache_ttl=55
err_log="$cache_dir/ai-panel.err"

mkdir -p "$cache_dir"

now_epoch() {
  date +%s
}

cache_fresh() {
  [[ -f "$cache_file" ]] || return 1
  local modified_at age
  modified_at=$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file")
  age=$(( $(now_epoch) - modified_at ))
  (( age < cache_ttl ))
}

ccusage_cmd() {
  local codex_bin

  if command -v ccusage-codex >/dev/null 2>&1; then
    ccusage-codex "$@"
    return
  fi

  while IFS= read -r codex_bin; do
    [[ -n "$codex_bin" ]] || continue
    if "$codex_bin" "$@"; then
      return
    fi
  done < <(
    find "$HOME/.npm/_npx" -path '*/node_modules/.bin/ccusage-codex' -printf '%T@ %p\n' 2>/dev/null \
      | sort -nr \
      | awk '{ print $2 }'
  )

  return 127
}

active_agents_count() {
  if ! command -v workmux >/dev/null 2>&1; then
    echo 0
    return
  fi

  if ! command -v jq >/dev/null 2>&1; then
    echo 0
    return
  fi

  workmux status --json 2>/dev/null | jq '
    if type == "array" then
      length
    elif (type == "object") and (has("sessions")) and (.sessions | type == "array") then
      (.sessions | length)
    else
      0
    end
  '
}

render_error() {
  local agents details
  agents=$(active_agents_count)
  details="Codex usage unavailable."

  if [[ -s "$err_log" ]]; then
    details=$(tail -n 1 "$err_log")
  fi

  jq -cn \
    --arg text "<span foreground='#D699B6'>󰚩 ${agents}</span> <span foreground='#d2788c'>ccusage n/a</span>" \
    --arg tooltip "AI panel\nActive agents: ${agents}\n${details}" \
    '{text: $text, tooltip: $tooltip, class: ["ai-panel", "warning"], alt: "ai-panel"}'
}

build_payload() {
  local today month_start daily_json monthly_json today_cost month_cost agents text tooltip

  today=$(date +%F)
  month_start=$(date +%Y-%m-01)

  daily_json=$(ccusage_cmd daily --json --since "$today" --until "$today" --timezone "$timezone")
  monthly_json=$(ccusage_cmd monthly --json --since "$month_start" --until "$today" --timezone "$timezone")

  # Old ccusage used `totalCost`; newer Codex-only output uses `costUSD`.
  today_cost=$(jq -r '.totals.costUSD // .totals.totalCost // .daily[0].costUSD // .daily[0].totalCost // 0' <<<"$daily_json")
  month_cost=$(jq -r '.totals.costUSD // .totals.totalCost // .monthly[0].costUSD // .monthly[0].totalCost // 0' <<<"$monthly_json")
  agents=$(active_agents_count)

  printf -v text "<span foreground='#D699B6'>󰚩 %s</span> <span foreground='#DBBC7F'>󰾆 $%.2f</span> <span foreground='#88C096'>󰃭 $%.2f</span>" "$agents" "$today_cost" "$month_cost"
  printf -v tooltip 'AI panel\nActive agents: %s\nToday: $%.2f\nMonth: $%.2f\nTimezone: %s' "$agents" "$today_cost" "$month_cost" "$timezone"

  jq -cn --arg text "$text" --arg tooltip "$tooltip" \
    '{text: $text, tooltip: $tooltip, class: ["ai-panel"], alt: "ai-panel"}'
}

if cache_fresh; then
  cat "$cache_file"
  exit 0
fi

if [[ -f "$err_log" ]]; then
  : >"$err_log"
fi

if payload=$(build_payload 2>>"$err_log"); then
  printf '%s\n' "$payload" >"$cache_file"
  printf '%s\n' "$payload"
  exit 0
fi

if [[ -f "$cache_file" ]]; then
  cat "$cache_file"
  exit 0
fi

render_error
