# tallylight

Per-window Claude Code status lights for macOS Terminal.app.

When you run several [Claude Code](https://claude.com/claude-code) sessions side by side,
tallylight shows which Terminal window is working, idle, waiting for your input, failed, or
dead — without clicking through every window.

![demo](docs/demo.gif)

| Light | Status |
|---|---|
| ![working](docs/badge-working.png) | **working** — Claude is doing something |
| ![idle](docs/badge-idle.png) | **idle** — finished, waiting for you |
| ![needs input](docs/badge-needs-input.png) | **needs input** — permission prompt or a question |
| ![error](docs/badge-error.png) | **error** — the turn failed |
| ![stale](docs/badge-stale.png) | **stale** — the claude process is gone |

The name: a tally light is the little red lamp on a broadcast camera that tells everyone which
camera is live. Same idea, for terminals.

Works with: macOS Terminal.app, local Claude Code sessions, multiple windows and displays.
Does not support: iTerm2, tmux, SSH/remote sessions (see [alternatives](#alternatives)).

No network access. No telemetry. Status files stay under `~/.claude/status/`.

## Install

```
git clone https://github.com/Azy02/tallylight
cd tallylight
./tallylight install
```

or with Homebrew:

```
brew install Azy02/tap/tallylight
tallylight install
```

`install` copies the hooks, loads the overlay LaunchAgent, and prints the hook config to merge
into your `~/.claude/settings.json`. Then:

```
tallylight doctor      # checks permissions, hooks, LaunchAgent, status files
tallylight restart
tallylight uninstall
```

On first run macOS asks: *"osascript wants to control Terminal"*. Allow it — that's how sessions
get matched to windows. Deny it and no lights ever appear.

## How it works

Terminal.app has no API for coloring its own tabs or titlebars (iTerm2 does). So tallylight
draws its own tiny borderless window on top of each Terminal window and keeps it in place.

- **Hooks** (`status-indicator.sh`, `status-cleanup.sh`): Claude Code runs these on
  prompt/stop/notification events; they write one JSON status file per session under
  `~/.claude/status/`, including the claude process id.
- **Overlay** (`corner-overlay.jxa`): a launchd-managed background process that watches those
  files and the Terminal windows and draws the lights. Starts at login, restarts if it dies.

The light hides the moment you grab a titlebar and comes back a few frames after the window
settles. Moves it can't see coming — Magnet and other keyboard window managers, menu tiling,
scripts — are caught by a 30 Hz position check within a frame or two. If a session's claude
process dies, its light turns gray within a couple of seconds.

## Where this fits

| Tool type | What it solves | What tallylight solves |
|---|---|---|
| Claude statusline | info inside the current session | which window needs attention |
| Notification hooks | a one-time alert | persistent visible state |
| Usage dashboards | cost/token monitoring | per-window workflow state |
| iTerm2 tab tools | iTerm2 users | Apple Terminal.app users |

## Alternatives

iTerm2 users should use its real API instead:
[JasperSui/claude-code-iterm2-tab-status](https://github.com/JasperSui/claude-code-iterm2-tab-status),
[STRML/cc-iterm2-tab-alert](https://github.com/STRML/cc-iterm2-tab-alert).
For tmux/remote sessions:
[accessd/tmux-agent-indicator](https://github.com/accessd/tmux-agent-indicator),
[samleeney/tmux-agent-status](https://github.com/samleeney/tmux-agent-status).

tallylight is for people staying in Terminal.app anyway.

## License

MIT
