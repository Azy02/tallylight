#!/bin/bash
# Installs the Claude Code Terminal.app status indicator: copies the hook scripts and overlay
# script into ~/.claude/hooks/, generates and loads a LaunchAgent for the overlay, and prints the
# settings.json hook configuration you still need to add yourself.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DEST="$HOME/.claude/hooks"
PLIST_DEST="$HOME/Library/LaunchAgents/com.tallylight.overlay.plist"

echo "Installing to $HOOKS_DEST ..."
mkdir -p "$HOOKS_DEST"

for f in corner-overlay.jxa status-indicator.sh status-cleanup.sh; do
  if [ -e "$HOOKS_DEST/$f" ]; then
    echo "  $f already exists at destination — leaving it alone (remove it first if you want to reinstall)."
  else
    cp "$SCRIPT_DIR/hooks/$f" "$HOOKS_DEST/$f"
    chmod +x "$HOOKS_DEST/$f" 2>/dev/null || true
    echo "  installed $f"
  fi
done

echo "Writing LaunchAgent to $PLIST_DEST ..."
cat > "$PLIST_DEST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.tallylight.overlay</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/osascript</string>
        <string>-l</string>
        <string>JavaScript</string>
        <string>$HOOKS_DEST/corner-overlay.jxa</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$HOOKS_DEST/corner-overlay.log</string>
    <key>StandardErrorPath</key>
    <string>$HOOKS_DEST/corner-overlay.err.log</string>
</dict>
</plist>
PLIST

launchctl unload "$PLIST_DEST" 2>/dev/null || true
launchctl load "$PLIST_DEST"
echo "LaunchAgent loaded — the overlay is running now and will start automatically at every login."

echo
echo "One manual step left: merge the hooks from"
echo "  $SCRIPT_DIR/settings-snippet.json"
echo "into your own ~/.claude/settings.json (do not overwrite the whole file with it)."
echo
echo "Read the README's 'Known limitations' section before relying on this day to day."
