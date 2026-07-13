---
type: Module
title: Hammerspoon automation
description: Keyboard-driven desktop switching, directional window focus, and keyboard-backlight control for macOS.
tags: [hammerspoon, macos, automation]
timestamp: 2026-07-13T18:18:21Z
sources: [.hammerspoon/**]
source_commit: 079fc9a1170fec06e93de4981e1c4ac5ef94fc18
---

# Responsibility

The only part of these dotfiles with real runtime logic (Lua). It owns three
independent keyboard concerns — one file each — wired together by `init.lua`:

* **Desktop switching** (`spaces.lua`) — Option+`N` jumps to Desktop N, with
  i3-style back-and-forth when you press it while already on N.
* **Directional window focus** (`window_focus.lua`) — Option+`H/J/K/L` moves
  keyboard focus to the window in that direction.
* **Keyboard backlight** (`keyboard_backlight.lua`) — Command+F1/F2 step the
  backlight down/up.

The current keybinding table lives in the repo's `README.md`; it is not
repeated here.

# Design principle: drive macOS, don't replace it

Every feature works by **synthesizing the native macOS key event** and letting
the OS do the work, rather than calling Hammerspoon's high-level `hs.spaces` /
brightness APIs. The native path is fast and reliable; the high-level APIs are
slow, animated, or outright broken on current macOS. This is
[decision 0002](/decisions/0002-synthesize-native-macos-shortcuts.md), and it is
the single idea that explains most of the code.

# Boundaries

* Requires macOS **Accessibility** (and, for the backlight, Input Monitoring)
  permission — without it every hotkey is a silent no-op. Grant it per README.
* The `hs` CLI is enabled (`require("hs.ipc")`) so features can be poked from a
  terminal, e.g. `hs -c "dumpSpaces()"`.
* Each module is self-contained; `init.lua` only `require`s them. There is no
  shared state between the three.

# Invariants & gotchas

* Long-lived watchers/eventtaps must be
  [stored in globals or they get garbage-collected](/gotchas/hammerspoon-watchers-must-be-global.md).
* Claiming Option+digit and Option+`HJKL`
  [suppresses the macOS Option-key special characters](/gotchas/option-modifier-eats-special-chars.md).

# Open questions

* Moving a window *between* desktops relies on a fragile workaround because the
  clean API is broken —
  [move-window-between-desktops](/questions/move-window-between-desktops.md).
