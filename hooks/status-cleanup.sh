#!/bin/bash
# Removes this session's status file when the session ends cleanly.
STATUS_DIR="$HOME/.claude/status"
INPUT=$(cat)
SESSION_ID=$(printf '%s' "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('session_id','unknown'))" 2>/dev/null)
[ -n "$SESSION_ID" ] && rm -f "$STATUS_DIR/$SESSION_ID.json"
