#!/usr/bin/env bash

set -euo pipefail

timezone="${TZ:-Europe/Oslo}"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
cache_file="$cache_dir/ai-panel.json"
cache_ttl=300

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
  if command -v bunx >/dev/null 2>&1; then
    bunx @ccusage/codex@latest "$@"
    return
  fi

  if command -v npx >/dev/null 2>&1; then
    npx -y @ccusage/codex@latest "$@"
    return
  fi

  return 127
}

active_agents_count() {
  if ! command -v workmux >/dev/null 2>&1; then
    echo 0
    return
  fi

  workmux status --json 2>/dev/null | jq 'length'
}

render_error() {
  local agents
  agents=$(active_agents_count)

  jq -cn \
    --arg text "<span foreground='#D699B6'>󰚩 ${agents}</span> <span foreground='#d2788c'>ccusage n/a</span>" \
    --arg tooltip "AI panel\nActive agents: ${agents}\nCodex usage unavailable." \
    '{text: $text, tooltip: $tooltip, class: ["ai-panel", "warning"], alt: "ai-panel"}'
}

build_payload() {
  local today month_start daily_json monthly_json today_cost month_cost agents text tooltip

  today=$(date +%F)
  month_start=$(date +%Y-%m-01)

  daily_json=$(ccusage_cmd daily --json --since "$today" --until "$today" --timezone "$timezone")
  monthly_json=$(ccusage_cmd monthly --json --since "$month_start" --until "$today" --timezone "$timezone")

  today_cost=$(jq -r '.daily[0].costUSD // 0' <<<"$daily_json")
  month_cost=$(jq -r '.monthly[0].costUSD // 0' <<<"$monthly_json")
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

if payload=$(build_payload 2>/dev/null); then
  printf '%s\n' "$payload" >"$cache_file"
  printf '%s\n' "$payload"
  exit 0
fi

if [[ -f "$cache_file" ]]; then
  cat "$cache_file"
  exit 0
fi

render_error
