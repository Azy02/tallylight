#!/bin/bash
# Writes a per-session status file for the corner-overlay indicator.
# Usage: status-indicator.sh <status-key>   where status-key is one of:
#   working | idle | needs-input | error | observe
# "observe" logs the raw Notification-hook payload to _notification_log.jsonl
# without touching the visible status file — used for notification_type
# values (agent_completed) whose mapping to a status color isn't confirmed
# yet, so we can inspect real payloads before guessing wrong in public.
STATUS_KEY="$1"
STATUS_DIR="$HOME/.claude/status"
mkdir -p "$STATUS_DIR"

INPUT=$(cat)
SESSION_ID=$(printf '%s' "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('session_id','unknown'))" 2>/dev/null)
CWD=$(printf '%s' "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('cwd',''))" 2>/dev/null)
[ -z "$SESSION_ID" ] && SESSION_ID="unknown-$$"

UPDATED=$(date +%s)

# Log raw Notification-hook payloads (identified by the notification_type
# field Claude Code includes) so the notification_type -> status mapping
# wired up in settings.json can be checked against real data rather than
# staying a guess. Env-vars, not string interpolation, since $INPUT is
# arbitrary JSON and unsafe to splice into a Python source string directly.
if printf '%s' "$INPUT" | grep -q '"notification_type"'; then
  STATUS_KEY_ENV="$STATUS_KEY" SESSION_ID_ENV="$SESSION_ID" UPDATED_ENV="$UPDATED" HOOK_RAW_INPUT="$INPUT" \
  python3 -c "
import json, os
line = {
    'status_key': os.environ.get('STATUS_KEY_ENV', ''),
    'session_id': os.environ.get('SESSION_ID_ENV', ''),
    'updated': int(os.environ.get('UPDATED_ENV', '0')),
    'payload': json.loads(os.environ.get('HOOK_RAW_INPUT') or '{}'),
}
with open(os.path.expanduser('~/.claude/status/_notification_log.jsonl'), 'a') as f:
    f.write(json.dumps(line) + chr(10))
" 2>/dev/null
fi

if [ "$STATUS_KEY" = "observe" ]; then
  exit 0
fi

# Walk up the process tree to find the real controlling tty — the hook subprocess
# itself may be detached from any controlling terminal, but an ancestor (the claude
# CLI process itself) has the terminal's real tty.
find_tty() {
  local pid=$$
  local i
  for i in 1 2 3 4 5 6 7 8; do
    local tty
    tty=$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ')
    if [ -n "$tty" ] && [ "$tty" != "??" ]; then
      echo "/dev/$tty"
      return 0
    fi
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
    [ -z "$pid" ] && break
  done
  echo ""
}
TTY=$(find_tty)

# Walk up the same way to find the claude CLI process itself, so the overlay can tell a
# session that DIED (process gone -> gray "stale" badge) from one that is merely quiet.
# The hook's own parent is a transient shell wrapper, so $PPID alone is useless here.
find_claude_pid() {
  local pid=$$
  local i
  for i in 1 2 3 4 5 6 7 8; do
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
    [ -z "$pid" ] || [ "$pid" = "1" ] && break
    # Match the executable name exactly — a loose grep on the full command line also matches
    # transient shell wrappers whose args merely contain a ~/.claude/... path, and recording
    # one of those (it exits immediately) would mark every session stale.
    case "$(basename "$(ps -o comm= -p "$pid" 2>/dev/null | tr -d ' ')" 2>/dev/null)" in
      claude) echo "$pid"; return 0 ;;
    esac
  done
  echo ""
}
CLAUDE_PID=$(find_claude_pid | tr -dc '0-9')

LABEL=$(basename "$CWD" 2>/dev/null)
[ -z "$LABEL" ] && LABEL="$SESSION_ID"

python3 -c "
import json
path = '$STATUS_DIR/$SESSION_ID.json'
with open(path, 'w') as f:
    json.dump({
        'status': '$STATUS_KEY',
        'tty': '$TTY',
        'label': '''$LABEL''',
        'updated': $UPDATED,
        'pid': ${CLAUDE_PID:-0},
    }, f)
"
