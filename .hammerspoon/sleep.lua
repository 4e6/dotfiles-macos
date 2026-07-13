-- sleep.lua
-- Command+F6 -> put the Mac to sleep, exactly like closing the lid.
--   * If `caffeinate` is running, DON'T sleep -- just lock the screen instead.
--     (You caffeinated on purpose to keep the machine awake, so Cmd+F6 falls
--     back to only locking rather than sleeping.)
--
-- WHY KEYCODE 178 AND NOT "f6":
--   On this Mac "Use F1..F12 as standard function keys" is OFF, so the top-row
--   keys emit their special function rather than an F-key keycode. Unlike F1/F2
--   -- which emit BRIGHTNESS_* *media* events that a keycode hotkey can't see
--   (see keyboard_backlight.lua) -- F6 emits a plain keyDown, just with an
--   unusual keycode. Verified on this Mac:
--     * bare Command+F6  -> keyDown keycode 178   <-- what we bind
--     * Command+Fn+F6    -> keyDown keycode 97    (the real "f6" keycode)
--   We bind the bare-press keycode so a plain Cmd+F6 (no Fn) triggers it.

local MODS   = { "cmd" }
local F6_KEY = 178   -- what a bare Command+F6 emits on this Mac (F6's Focus fn)

-- True while the `caffeinate` CLI is holding the Mac awake. Absolute path
-- because hs.execute runs commands with a minimal PATH.
local function caffeinateRunning()
    local _, ok = hs.execute("/usr/bin/pgrep -x caffeinate")
    return ok == true
end

-- Lid-close behaviour: sleep, unless caffeinated -- then only lock the screen.
local function sleepLikeLidClose()
    if caffeinateRunning() then
        hs.caffeinate.lockScreen()
    else
        hs.caffeinate.systemSleep()
    end
end

-- Kept in a GLOBAL on purpose, like the watchers/eventtaps in the other modules:
-- a local reference would be garbage-collected and the hotkey would silently die.
sleepHotkey = hs.hotkey.bind(MODS, F6_KEY, sleepLikeLidClose)
