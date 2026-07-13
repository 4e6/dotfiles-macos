---
type: Open Question
title: How should we move a window between desktops once the native API works again?
description: hs.spaces.moveWindowToSpace is broken on macOS 15+/26; a fragile simulated-drag workaround is in use.
status: open
tags: [hammerspoon, macos]
timestamp: 2026-07-13T18:18:21Z
---

# Question

`hs.spaces.moveWindowToSpace()` is the clean way to send the focused window to
another desktop, but it is **broken on macOS 15 Sequoia and 26 Tahoe** (upstream
[Hammerspoon #3698](https://github.com/Hammerspoon/hammerspoon/issues/3698)): it
returns `true` but the window never changes space. Apple changed the private
SkyLight API Hammerspoon drove; confirmed a silent no-op on this machine.

# Current workaround

`moveFocusedWindowToSpace` in `spaces.lua` reproduces the manual gesture:
synthesize a mouse-down on the window's title bar, fire the native
[Ctrl+N desktop switch](/decisions/0002-synthesize-native-macos-shortcuts.md)
while "holding" it, then release. The held window rides along.

Its limitations — why this is still an open question, not a finished feature:

* It **follows** the window to the destination — there is no "send and stay".
* Existing desktops only (same constraint as switching).
* Unreliable for tab-strip apps whose title bar is interactive (e.g. Chrome — the
  grab lands on a tab); standard title-bar apps (Finder, terminals) work.
* Not multi-monitor aware. (Note: moving to a space on a *different* screen is
  reportedly the one case where the broken native API still works — see #3698 if
  multi-monitor support is ever needed.)
* Simulated drag with fixed ~210 ms of sleeps; heavy system load could race the
  timing.
* Briefly hijacks the real mouse cursor.

# Resolution trigger

Re-test the clean API after any macOS or Hammerspoon update. `spaces.lua` carries
a ready-to-paste `hs -c` snippet that prints the window's space id before/after a
`moveWindowToSpace` call; if "after" shows the new id, delete the workaround and
call the API directly. Environment when the workaround was written: macOS 26.5.1
(25F80), Hammerspoon 1.1.1, 2026-06-24.
