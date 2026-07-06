-- keyboard_backlight.lua
-- Keyboard backlight hotkeys:
--   * Command+F1  -> dim one step      (works with or without Fn)
--   * Command+F2  -> brighten one step (works with or without Fn)
--
-- HOW THE BACKLIGHT IS DRIVEN:
--   On Apple Silicon the keyboard-backlight level is not readable (it lives in
--   the SMC / CoreBrightness, not in ioreg) and there's no working "set to X".
--   What DOES work is posting the system key events ILLUMINATION_UP /
--   ILLUMINATION_DOWN -- the same signals behind the hardware keyboard-brightness
--   controls -- one notch per event. So these hotkeys just nudge the level a step.
--
--   If nothing happens at all, Hammerspoon is probably missing Accessibility
--   (and/or Input Monitoring) permission -- see README step 6.

local STEP_MODS  = { "cmd" }   -- Command
local DIM_KEY    = "f1"        -- Command+F1 -> dim   one step
local BRIGHT_KEY = "f2"        -- Command+F2 -> bright one step

-- One backlight notch in the given direction ("ILLUMINATION_UP" / "..._DOWN").
local function stepBacklight(illum)
    hs.eventtap.event.newSystemKeyEvent(illum, true):post()
    hs.eventtap.event.newSystemKeyEvent(illum, false):post()
end

-- SINGLE-STEP DIM / BRIGHTEN on Command+F1 / Command+F2. This needs TWO
-- mechanisms, because the top-row keys behave differently depending on Fn:
--
--   * Command + Fn + F1/F2   -> macOS sends the real F1/F2 KEYCODE, which a
--     normal hs.hotkey catches. (The two binds just below.)
--   * Command + F1/F2 (no Fn) -> macOS sends a DISPLAY-BRIGHTNESS media event
--     (BRIGHTNESS_DOWN / BRIGHTNESS_UP), NOT an F-key keycode -- so a keycode
--     hotkey never sees it. The eventtap below catches that media event and,
--     ONLY while Command is held, swallows it and fires keyboard-backlight
--     instead. Without Command the event passes through untouched, so plain
--     F1/F2 keeps controlling DISPLAY brightness as usual.
--     (Verified on this Mac: Cmd+F1 -> {key=BRIGHTNESS_DOWN, cmd=true}.)

-- Fn variant (raw F1/F2 keycode):
hs.hotkey.bind(STEP_MODS, DIM_KEY,    function() stepBacklight("ILLUMINATION_DOWN") end)
hs.hotkey.bind(STEP_MODS, BRIGHT_KEY, function() stepBacklight("ILLUMINATION_UP")   end)

-- No-Fn variant (display-brightness media event). Kept in a GLOBAL on purpose,
-- exactly like spaceWatcher in spaces.lua: a local eventtap would be
-- garbage-collected and silently stop firing.
keyboardBacklightTap = hs.eventtap.new({ hs.eventtap.event.types.systemDefined }, function(event)
    local sysKey = event:systemKey()
    if not (sysKey and sysKey.key) then return false end

    local illum
    if     sysKey.key == "BRIGHTNESS_DOWN" then illum = "ILLUMINATION_DOWN"
    elseif sysKey.key == "BRIGHTNESS_UP"   then illum = "ILLUMINATION_UP"
    else return false end -- some other media key (volume, play, our own ILLUMINATION_*, ...)

    -- Leave display brightness alone unless Command is held.
    if not event:getFlags().cmd then return false end

    if sysKey.down then stepBacklight(illum) end -- fire once per press / auto-repeat
    return true                                  -- swallow so display brightness stays put
end)
keyboardBacklightTap:start()
