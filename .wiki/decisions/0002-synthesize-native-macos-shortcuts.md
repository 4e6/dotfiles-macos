---
type: Decision
title: Drive desktop/window actions by synthesizing native macOS shortcuts
description: Hammerspoon posts the native Ctrl+digit key events instead of calling hs.spaces navigation APIs.
status: accepted
tags: [hammerspoon, macos]
timestamp: 2026-07-13T18:18:21Z
---

# Context

The [Hammerspoon module](/architecture/hammerspoon.md) needs to switch desktops
and move windows between them — fast, and without animation getting in the way.
Hammerspoon exposes `hs.spaces.gotoSpace()` / `hs.spaces.moveWindowToSpace()`
for exactly this.

# Decision

Do **not** use the high-level `hs.spaces` navigation APIs. Instead synthesize the
native macOS "Switch to Desktop N" shortcut — `Ctrl`+digit (digit `0` = Desktop
10) — with `hs.eventtap`, and let WindowServer perform the switch.

# Alternatives considered

* **`hs.spaces.gotoSpace()`** — rejected: routes through Mission Control, which
  is slow, animated, and can get *stuck* in the Mission Control view if the
  triggering modifier is still held.
* **Bind `Ctrl`+digit directly in Hammerspoon** — rejected: it collides with the
  macOS-owned shortcut (`RegisterEventHotKey` fails with `-9878`). macOS owns
  `Ctrl`+digit, so we synthesize it rather than re-bind it.
* **`hs.spaces.moveWindowToSpace()` for the move case** — rejected: broken on
  current macOS, see [open question](/questions/move-window-between-desktops.md).

# Consequences

* Switching only works for desktops that **already exist** — `Ctrl`+N is a no-op
  until Desktop N is created (at which point macOS auto-binds it).
* **Desktop 10 needs one manual step**: macOS auto-binds `Ctrl+1..9` but *not*
  `Ctrl+0`, so Option+0 does nothing until you map "Switch to Desktop 10" =
  `Ctrl+0` by hand (System Settings → Keyboard → Keyboard Shortcuts → Mission
  Control). Documented in the README.
* Because we bind the Option+digit / Option+letter triggers, those
  [Option-key special characters can no longer be typed](/gotchas/option-modifier-eats-special-chars.md).
