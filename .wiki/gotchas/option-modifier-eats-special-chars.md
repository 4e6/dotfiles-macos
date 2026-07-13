---
type: Gotcha
title: Option+digit / Option+HJKL hotkeys eat macOS special characters
description: Binding these in Hammerspoon suppresses the Option-key character composition normally on those keys.
tags: [hammerspoon, macos, keyboard]
timestamp: 2026-07-13T18:18:21Z
---

# Symptom

Option+digit no longer types `¡ ™ £ ¢ ∞ § … º`, and Option+`H/J/K/L` no longer
types `˙ ∆ ˚ ¬`. As text input they appear to do nothing.

# Cause

The [Hammerspoon module](/architecture/hammerspoon.md) binds Option+digit for
desktop switching and Option+`HJKL` for
[directional window focus](/decisions/0002-synthesize-native-macos-shortcuts.md).
Hammerspoon grabs those keystrokes before macOS performs Option-key character
composition, so the special characters are never typed.

# Fix

It's a deliberate trade-off and rarely a problem in practice. If you need those
characters, change the modifier: `SWITCH_MODS` / `MOVE_MODS` in `spaces.lua` and
`MODS` in `window_focus.lua`.
