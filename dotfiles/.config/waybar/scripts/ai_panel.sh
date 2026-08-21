#!/usr/bin/env bash

set -euo pipefail

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

timezone="${TZ:-Europe/Oslo}"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
cost_cache="$cache_dir/ai-costs.json"
cache_ttl=55
err_log="$cache_dir/ai-panel.err"
oak_state_dir="${OAK_TREE_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/oak-tree}"

mkdir -p "$cache_dir"

cache_fresh() {
  [[ -f "$cost_cache" ]] || return 1
  (( $(date +%s) - $(stat -c %Y "$cost_cache") < cache_ttl ))
}

ccusage_cmd() {
  npx ccusage@latest "$@"
}

oak_tree_state() {
  python3 - "$oak_state_dir" <<'PY'
import json
import re
import subprocess
import sys
from pathlib import Path

state_dir = Path(sys.argv[1])
sessions_dir = state_dir / "sessions"
try:
    result = subprocess.run(
        ["tmux", "list-sessions", "-F", "#{session_name}"],
        text=True,
        capture_output=True,
        check=False,
    )
    active_tmux = set(result.stdout.splitlines()) if result.returncode == 0 else None
except OSError:
    active_tmux = None

counts = {"live": 0, "wait": 0, "ready": 0, "review": 0, "testing": 0}
sessions = []
for path in sessions_dir.glob("*.json") if sessions_dir.is_dir() else []:
    try:
        session = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        continue

    tmux_name = session.get("tmux_session_name", "")
    if active_tmux is not None and tmux_name and tmux_name not in active_tmux:
        continue

    tag = session.get("tag", "")
    status = session.get("agent_status", "")
    if tag == "waiting_review":
        state = "review"
    elif tag == "testing":
        state = "testing"
    elif status == "question":
        state = "wait"
    elif status == "working":
        state = "live"
    else:
        state = "ready"
    counts[state] += 1

    repo = session.get("repo_key") or Path(session.get("root", "session")).name
    repo = re.sub(r"-[0-9a-f]{8}$", "", repo)
    todo = session.get("todo") or {}
    sessions.append({
        "state": state,
        "repo": repo,
        "branch": session.get("branch", ""),
        "todo_completed": todo.get("completed"),
        "todo_total": todo.get("total"),
    })

priority = {"wait": 0, "live": 1, "ready": 2, "review": 3, "testing": 4}
sessions.sort(key=lambda item: (priority[item["state"]], item["repo"], item["branch"]))
print(json.dumps({**counts, "total": len(sessions), "sessions": sessions}))
PY
}

build_costs() {
  local today month_start month_period usage_json
  local non_pi_today non_pi_month pi_today pi_month

  today=$(date +%F)
  month_start=$(date +%Y-%m-01)
  month_period=$(date +%Y-%m)
  if ! usage_json=$(ccusage_cmd --json --by-agent --sections daily,monthly --since "$month_start" --until "$today" --timezone "$timezone"); then
    return 1
  fi
  non_pi_today=$(jq -r --arg period "$today" \
    '[.daily[] | select(.period == $period) | .agents[]? | select(.agent != "pi") | .totalCost] | add // 0' <<<"$usage_json")
  non_pi_month=$(jq -r --arg period "$month_period" \
    '[.monthly[] | select(.period == $period) | .agents[]? | select(.agent != "pi") | .totalCost] | add // 0' <<<"$usage_json")
  pi_today=$(jq -r --arg period "$today" \
    '[.daily[] | select(.period == $period) | .agents[]? | select(.agent == "pi") | .totalCost] | add // 0' <<<"$usage_json")
  pi_month=$(jq -r --arg period "$month_period" \
    '[.monthly[] | select(.period == $period) | .agents[]? | select(.agent == "pi") | .totalCost] | add // 0' <<<"$usage_json")

  jq -cn \
    --argjson pi_today "$pi_today" --argjson pi_month "$pi_month" \
    --argjson non_pi_today "$non_pi_today" --argjson non_pi_month "$non_pi_month" \
    --arg timezone "$timezone" \
    '{available: true, pi_today: $pi_today, pi_month: $pi_month, non_pi_today: $non_pi_today, non_pi_month: $non_pi_month, all_today: ($pi_today + $non_pi_today), all_month: ($pi_month + $non_pi_month), today: $pi_today, month: $pi_month, timezone: $timezone}'
}

load_costs() {
  local costs tmp
  if cache_fresh && jq -e '.available == true' "$cost_cache" >/dev/null 2>&1; then
    cat "$cost_cache"
    return
  fi

  if costs=$(build_costs 2>>"$err_log"); then
    tmp="$cost_cache.tmp"
    printf '%s\n' "$costs" >"$tmp"
    mv "$tmp" "$cost_cache"
    printf '%s\n' "$costs"
  elif [[ -s "$cost_cache" ]]; then
    cat "$cost_cache"
  else
    jq -cn --arg error "$(tail -n 1 "$err_log" 2>/dev/null || true)" \
      '{available: false, today: 0, month: 0, error: $error}'
  fi
}

render_payload() {
  python3 - "$1" "$2" <<'PY'
import html
import json
import sys

oak = json.loads(sys.argv[1])
cost = json.loads(sys.argv[2])
parts = ["<span foreground='#be8c8c'><b>AI //</b></span>"]
classes = ["ai-panel"]

parts.append(f"<span foreground='#8faf77'><b>{oak['live']} WORKING</b></span>")
parts.append(f"<span foreground='#7894ab'>{oak['ready']} IDLE</span>")
classes.append("working" if oak["live"] else "idle")
if oak["wait"]:
    parts.append(f"<span foreground='#e6be8c'><b>{oak['wait']} WAIT</b></span>")
    classes.append("attention")
if oak["ready"]:
    parts.append(f"<span foreground='#7894ab'>{oak['ready']} READY</span>")
if oak["review"]:
    parts.append(f"<span foreground='#be8c8c'>{oak['review']} REVIEW</span>")
if oak["testing"]:
    parts.append(f"<span foreground='#b4b4ce'>{oak['testing']} TEST</span>")
if cost.get("available"):
    parts.append(
        f"<span foreground='#DBBC7F'>${cost['today']:.2f}</span>"
        f" <span foreground='#747d91'>/</span> "
        f"<span foreground='#8faf77'>${cost['month']:.2f}</span>"
    )
else:
    parts.append("<span foreground='#d2788c'>COST N/A</span>")

labels = {
    "wait": "WAIT",
    "live": "WORK",
    "ready": "IDLE",
    "review": "REVIEW",
    "testing": "TEST",
}
tooltip = [f"Oak Tree · {oak['total']} sessions", ""]
for session in oak["sessions"]:
    detail = f"{labels[session['state']]:<6}  {session['repo']}"
    if session["branch"]:
        detail += f" · {session['branch']}"
    if session["todo_total"]:
        detail += f" · todo {session['todo_completed']}/{session['todo_total']}"
    tooltip.append(detail)
if not oak["sessions"]:
    tooltip.append("No live Oak Tree sessions")
if cost.get("available"):
    tooltip.extend([
        "",
        f"Pi usage cost · {cost.get('timezone', 'local')}",
        f"Today Pi ${cost.get('pi_today', 0):.2f} · all agents ${cost.get('all_today', cost.get('today', 0) + cost.get('non_pi_today', 0)):.2f}",
        f"Month Pi ${cost.get('pi_month', 0):.2f} · all agents ${cost.get('all_month', cost.get('month', 0) + cost.get('non_pi_month', 0)):.2f}",
    ])
else:
    tooltip.extend(["", f"Cost unavailable: {cost.get('error') or 'usage parsing failed'}"])

print(json.dumps({
    "text": "  ·  ".join(parts),
    "tooltip": html.escape("\n".join(tooltip)),
    "class": classes,
    "alt": "attention" if oak["wait"] else "ai",
}, ensure_ascii=False))
PY
}

: >"$err_log"
oak_json=$(oak_tree_state 2>>"$err_log" || printf '%s' '{"live":0,"wait":0,"ready":0,"review":0,"testing":0,"total":0,"sessions":[]}')
cost_json=$(load_costs)
render_payload "$oak_json" "$cost_json"
