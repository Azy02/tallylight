# tallylight

A tally light is the little red lamp on a broadcast camera that tells everyone which camera is
live. This is that, for [Claude Code](https://claude.com/claude-code) sessions in macOS
Terminal.app: each window running a session gets a light in its titlebar.

![badge in a Terminal titlebar](docs/badge-context.png)

| Badge | Status |
|---|---|
| ![working](docs/badge-working.png) | **working** — Claude is doing something |
| ![idle](docs/badge-idle.png) | **idle** — finished, waiting for you |
| ![needs input](docs/badge-needs-input.png) | **needs input** — permission prompt or a question |
| ![error](docs/badge-error.png) | **error** — the turn failed |

Made for running several sessions side by side: you can see which window needs you without
clicking through them.

## How it works

Terminal.app has no API for coloring its own tabs or titlebars (iTerm2 does — see
[alternatives](#alternatives)). So this draws its own borderless little window on top of each
Terminal window and keeps it in place.

Two parts:

- **Hooks** (`status-indicator.sh`, `status-cleanup.sh`): Claude Code runs these on prompt/stop/
  notification events; they write one JSON status file per session under `~/.claude/status/`.
- **Overlay** (`corner-overlay.jxa`): a background process, managed by launchd, that watches
  those files and the Terminal windows and draws the badges. Starts at login, restarts if it
  dies.

The badge hides the moment you grab a titlebar and comes back a few frames after the window
settles. Moves it can't see coming (Magnet and other keyboard window managers, menu tiling,
scripts) are caught by a 30 Hz position check within a frame or two.

## Install

```
./install.sh
```

Copies the scripts to `~/.claude/hooks/`, loads the LaunchAgent, and prints the hook config for
you to merge into `~/.claude/settings.json` yourself.

On first run macOS asks: *"osascript wants to control Terminal"*. Allow it — that's how sessions
get matched to windows. If you deny it, no badges ever appear.

## Cost and caveats

- **CPU**: ~13% of one core at idle, mostly the 30 Hz position check. On a 12-core machine
  that's ~1% overall. `PULSE_INTERVAL` in `corner-overlay.jxa` is the knob if you'd rather have
  cycles than responsiveness.
- **Rare crash**: EXC_BAD_ACCESS in autorelease pool draining, roughly once in several hours.
  launchd restarts the overlay within seconds; you might catch the badges blinking once.
- Local Terminal.app sessions only. Nothing over SSH or inside tmux.

## Alternatives

If you use iTerm2, use its real API instead:
[JasperSui/claude-code-iterm2-tab-status](https://github.com/JasperSui/claude-code-iterm2-tab-status),
[STRML/cc-iterm2-tab-alert](https://github.com/STRML/cc-iterm2-tab-alert).
For tmux/remote sessions:
[accessd/tmux-agent-indicator](https://github.com/accessd/tmux-agent-indicator),
[samleeney/tmux-agent-status](https://github.com/samleeney/tmux-agent-status).

This exists for people staying in Terminal.app anyway.

## License

MIT
