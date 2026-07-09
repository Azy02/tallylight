# claude-terminal-indicator

A live, per-window status light for [Claude Code](https://claude.com/claude-code) sessions running
in macOS Terminal.app. If you run several Claude Code sessions in separate Terminal windows at
once, this draws a small colored badge in each window's titlebar area — gold while it's working,
green when it's idle and waiting on you, blue when it specifically needs your input (a permission
prompt, a clarifying question), red on a failed turn — so you can tell which of several windows
needs attention without switching to each one.

## Why this exists

Terminal.app has no scriptable way to recolor its own chrome — no tab badges, no title-color API,
nothing like what iTerm2 or tmux expose natively (see **Alternatives** below if you can use either
of those instead; this project only exists because Terminal.app doesn't give you that option). The
only way to get a colored indicator that visually tracks a specific Terminal window is to draw a
separate, borderless window on top of it and keep repositioning that window to match — which is
exactly what this does, using `CGWindowListCopyWindowInfo` to track window position live, including
during drags, without depending on Terminal's own (dragslowing) Apple Events interface.

## How it works

Two independent pieces:

1. **Claude Code hooks** (`status-indicator.sh`, `status-cleanup.sh`) write a small JSON file per
   session to `~/.claude/status/` every time something happens — a new prompt, a finished turn, a
   permission request, a failure. This is the only part that talks to Claude Code.
2. **The overlay** (`corner-overlay.jxa`), a persistent background process, watches that directory
   and Terminal's windows, and keeps a small colored rounded-rectangle positioned over each
   session's window, recolored to match its current status file.

The overlay runs as a `launchd` LaunchAgent — it starts automatically at login and restarts itself
immediately if it ever exits, so there's nothing to launch by hand.

## Install

```
./install.sh
```

This copies the hook scripts and the overlay script into `~/.claude/hooks/`, installs and loads the
LaunchAgent, and prints the hook configuration you need to merge into your own
`~/.claude/settings.json` (it will not touch that file for you — it's yours, and probably has other
settings in it already).

## Known limitations — read before you rely on this

This is not production-hardened software. Specifically, as of this writing:

- **Rare crash, not fully understood.** The process occasionally (unpredictably, on the order of
  hours) crashes with `EXC_BAD_ACCESS` during autorelease pool draining. Auto-restarted within a
  second or two by `KeepAlive`, but real. (A separate, once-serious memory leak —
  `CGWindowListCopyWindowInfo`'s Copy-rule return value never being released by the JXA bridge —
  was fixed by rebinding the window-list pipeline to opaque pointers the bridge takes no
  ownership of, so the script can release the array itself; see the `ObjC.bindFunction` comment
  in `corner-overlay.jxa` for why the naive `CFRelease` on the *object-bridged* value crashes
  instead.)
- **It's an overlay, not native chrome.** No amount of polish makes this *actually* part of
  Terminal's window — it's a separate window kept in sync by observing, which has an inherent
  check-then-react gap. The design leans into that instead of fighting it: the badge hides the
  instant you grab a titlebar (before the window has visibly moved) and reappears within a few
  frames of the window parking, and a 30Hz motion pulse catches every other kind of move —
  keyboard window managers like Magnet, menu-driven tiling, AppleScript — within a frame or two.
  The badge also sits one window level above normal windows (so a click-raise can never cover
  it), with software-emulated occlusion so it still hides correctly under genuinely overlapping
  windows. But it is not, and cannot be, part of the real window's own redraws.
- **It spends real CPU for that responsiveness**: roughly 13% of one core at idle (the 30Hz
  motion pulse dominates; that's ~0.5% of a modern many-core machine, but it is not free). The
  rate knob is `PULSE_INTERVAL` in `corner-overlay.jxa` if you'd rather trade latency for cycles.
- **First run triggers a macOS Automation prompt** ("osascript wants to control Terminal") —
  the overlay uses Apple Events once per new session to map a tty to its window. Deny it and
  badges never appear.
- Local Terminal.app sessions only. Remote/SSH sessions over tmux are not covered by this overlay
  — see Alternatives.

If any of this matters more to you than the convenience, seriously consider the alternatives below
before installing this.

## Alternatives (probably better, if available to you)

- **iTerm2 users**: this entire problem is already solved, natively, with none of the above
  tradeoffs, because iTerm2 exposes a real scriptable API for exactly this. See
  [`JasperSui/claude-code-iterm2-tab-status`](https://github.com/JasperSui/claude-code-iterm2-tab-status)
  or [`STRML/cc-iterm2-tab-alert`](https://github.com/STRML/cc-iterm2-tab-alert).
- **tmux / remote sessions**: see
  [`accessd/tmux-agent-indicator`](https://github.com/accessd/tmux-agent-indicator) or
  [`samleeney/tmux-agent-status`](https://github.com/samleeney/tmux-agent-status) — colors pane
  borders and status text natively through tmux, no overlay needed at all.

This project is specifically for people who want to keep using Terminal.app anyway.

## License

MIT — see LICENSE.
