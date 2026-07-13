---
type: Gotcha
title: Hammerspoon watchers and eventtaps must be stored in globals
description: A watcher/eventtap kept in a local variable is garbage-collected and silently stops firing.
tags: [hammerspoon, lua]
timestamp: 2026-07-13T18:18:21Z
---

# Symptom

A `hs.spaces.watcher` or `hs.eventtap` works right after a config reload, then
randomly stops firing minutes later — no error, no log, it just goes dead.

# Cause

Hammerspoon keeps the underlying OS callback alive only as long as the Lua object
is reachable. Assigned to a `local`, the object becomes unreachable once the
enclosing chunk finishes; Lua garbage-collects it and the callback is torn down.

# Fix

Store long-lived watchers/eventtaps in a **global** variable so they are never
collected. In this repo that is `spaceWatcher` in `spaces.lua` and
`keyboardBacklightTap` in `keyboard_backlight.lua` — both deliberately global,
and commented as such so nobody "tidies" them into locals.

See the [Hammerspoon module](/architecture/hammerspoon.md).
