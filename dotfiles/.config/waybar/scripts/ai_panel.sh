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
  bunx ccusage "$@"
}

# Pi forked sessions contain copied parent messages with their original usage.
# Count only assistant usage created after each session file's own start time.
deduped_pi_costs() {
  local sessions_dir="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/sessions"
  python3 - "$sessions_dir" "$timezone" <<'PY'
import json
import os
import sys
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

sessions_dir, timezone = sys.argv[1:]
tz = ZoneInfo(timezone)
now = datetime.now(tz)
today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
tomorrow = today_start + timedelta(days=1)
month_start = today_start.replace(day=1)
month_start_epoch = month_start.timestamp()
today_cost = 0.0
month_cost = 0.0


def timestamp(value):
    if isinstance(value, (int, float)):
        return value / 1000 if value > 1_000_000_000_000 else value
    if not isinstance(value, str):
        return None
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
        if parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=tz)
        return parsed.timestamp()
    except ValueError:
        return None


for root, _, files in os.walk(sessions_dir):
    for name in files:
        if not name.endswith(".jsonl"):
            continue
        path = os.path.join(root, name)
        try:
            if os.stat(path).st_mtime < month_start_epoch:
                continue
            session_start = None
            with open(path, encoding="utf-8") as stream:
                for line in stream:
                    try:
                        entry = json.loads(line)
                    except (json.JSONDecodeError, UnicodeDecodeError):
                        continue
                    if entry.get("type") == "session" and session_start is None:
                        session_start = timestamp(entry.get("timestamp"))
                        continue
                    message = entry.get("message", {})
                    if entry.get("type") != "message" or message.get("role") != "assistant":
                        continue
                    event_time = timestamp(entry.get("timestamp") or message.get("timestamp"))
                    if session_start is None or event_time is None or event_time < session_start:
                        continue
                    cost = message.get("usage", {}).get("cost", {}).get("total", 0)
                    if not isinstance(cost, (int, float)):
                        continue
                    if month_start.timestamp() <= event_time < tomorrow.timestamp():
                        month_cost += cost
                    if today_start.timestamp() <= event_time < tomorrow.timestamp():
                        today_cost += cost
        except OSError:
            continue

print(json.dumps({"today": today_cost, "month": month_cost}))
PY
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
  details="AI usage unavailable."

  if [[ -s "$err_log" ]]; then
    details=$(tail -n 1 "$err_log")
  fi

  jq -cn \
    --arg text "<span foreground='#D699B6'>󰚩 ${agents}</span> <span foreground='#d2788c'>ccusage n/a</span>" \
    --arg tooltip "AI panel\nActive agents: ${agents}\n${details}" \
    '{text: $text, tooltip: $tooltip, class: ["ai-panel", "warning"], alt: "ai-panel"}'
}

build_payload() {
  local today month_start month_period usage_json pi_json non_pi_today non_pi_month pi_today pi_month today_cost month_cost agents text tooltip

  today=$(date +%F)
  month_start=$(date +%Y-%m-01)
  month_period=$(date +%Y-%m)

  # Keep ccusage for non-Pi agents, but replace its duplicated Pi totals.
  usage_json=$(ccusage_cmd --json --by-agent --sections daily,monthly --since "$month_start" --until "$today" --timezone "$timezone")
  pi_json=$(deduped_pi_costs)

  non_pi_today=$(jq -r --arg period "$today" \
    '[.daily[] | select(.period == $period) | .agents[]? | select(.agent != "pi") | .totalCost] | add // 0' <<<"$usage_json")
  non_pi_month=$(jq -r --arg period "$month_period" \
    '[.monthly[] | select(.period == $period) | .agents[]? | select(.agent != "pi") | .totalCost] | add // 0' <<<"$usage_json")
  pi_today=$(jq -r '.today' <<<"$pi_json")
  pi_month=$(jq -r '.month' <<<"$pi_json")
  today_cost=$(jq -nr --argjson pi "$pi_today" --argjson other "$non_pi_today" '$pi + $other')
  month_cost=$(jq -nr --argjson pi "$pi_month" --argjson other "$non_pi_month" '$pi + $other')
  agents=$(active_agents_count)

  printf -v text "<span foreground='#D699B6'>󰚩 %s</span> <span foreground='#DBBC7F'>󰾆 $%.2f</span> <span foreground='#88C096'>󰃭 $%.2f</span>" "$agents" "$today_cost" "$month_cost"
  printf -v tooltip 'AI panel\nActive agents: %s\nToday: $%.2f\nMonth: $%.2f\nPi fork duplicates removed\nTimezone: %s' "$agents" "$today_cost" "$month_cost" "$timezone"

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
