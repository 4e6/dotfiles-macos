-- spaces.lua
-- Desktop switching + notes/diagnostics for Mission Control.
-- Inspired by: https://konradstaniszewski.com/blog/windows-between-spaces
--
-- DESKTOP SWITCHING:
--   * Ctrl+<number> -> macOS native "Switch to Desktop N", fast and direct
--     (managed by the Dock/WindowServer for every desktop that exists). We do
--     NOT bind Ctrl+N here -- it collided with macOS (RegisterEventHotKey
--     failed: -9878), so macOS owns it.
--   * Option+<number> -> we make this behave EXACTLY like Ctrl+N by synthesizing
--     a Ctrl+N keystroke. Calling hs.spaces.gotoSpace() instead routed through
--     Mission Control (slow, animated, and could get stuck in the MC view if the
--     modifier was held), so we avoid it. The synthetic Ctrl+N triggers the same
--     fast native path. Note: like the native shortcut, this only switches to
--     desktops that actually exist (Option+3 does nothing until Desktop 3 is
--     created, at which point macOS auto-binds Ctrl+3 and it starts working).
--
-- TRADE-OFF: binding Option+<number> means you can no longer TYPE the
-- Option+digit special characters (¡ ™ £ ¢ ∞ §) -- Hammerspoon consumes those
-- keystrokes. (Likewise the directional-focus binds in window_focus.lua claim
-- Option+H/J/K/L = ˙ ∆ ˚ ¬.) Rarely an issue; switch SWITCH_MODS if it is.

local log = hs.logger.new('Spaces', 'info')

local SWITCH_MODS = { "alt" }

-- Ordered list of real space IDs for a screen, restricted to regular desktops
-- (full-screen-app spaces are skipped so numbering matches Mission Control).
-- Space IDs on macOS are arbitrary (e.g. 1, 56), NOT the desktop position.
local function userSpaceIds(screenUUID)
    local ordered = hs.spaces.spacesForScreen(screenUUID) or {}
    local result = {}
    for _, spaceId in ipairs(ordered) do
        local ok, kind = pcall(hs.spaces.spaceType, spaceId)
        if not ok or kind == nil or kind == "user" then
            table.insert(result, spaceId)
        end
    end
    return result
end

-- Switch to a desktop number (1-based) by synthesizing the native, fast
-- Ctrl+<number> "Switch to Desktop N" shortcut.
function switchToDesktop(spaceNumber)
    local key = tostring(spaceNumber)
    hs.eventtap.event.newKeyEvent({ "ctrl" }, key, true):post()
    hs.eventtap.event.newKeyEvent({ "ctrl" }, key, false):post()
end

-- Bind Option + 1-6 to switch desktops.
for i = 1, 6 do
    hs.hotkey.bind(SWITCH_MODS, tostring(i), function() switchToDesktop(i) end)
end

-- ============================================================================
-- TICKET: moving the focused window TO another desktop is NOT implemented.
--
-- Goal (from the original article): cmd+shift+N moves the focused window to
-- Desktop N. This is currently impossible to do cleanly on this machine:
--
--   * hs.spaces.moveWindowToSpace() is a no-op on macOS 26 (Tahoe). It returns
--     true but the window never changes space (Apple changed the private
--     SkyLight API Hammerspoon relies on).
--   * Synthetic Ctrl+Arrow "move a space" key events are ignored by the system.
--   * The only thing that worked was a fragile "drag the title bar to the
--     screen edge and dwell until macOS auto-flips" gesture -- unreliable and
--     visually disruptive, so it was removed.
--
-- (Desktop *switching* is unaffected -- macOS handles Ctrl+N natively; see the
-- note at the top of this file.)
--
-- Filed: 2026-06-23. Environment: macOS 26.5.1 (build 25F80), Hammerspoon 1.1.1.
-- Upstream tracking: https://github.com/Hammerspoon/hammerspoon/issues
--   (search "moveWindowToSpace" + "Tahoe"/"macOS 26").
--
-- RE-TEST after any macOS or Hammerspoon update. With at least two desktops,
-- focus a window on Desktop 1, find another space id via dumpSpaces(), then:
--
--   hs -c "local w=hs.window.focusedWindow(); print('before '..hs.inspect(hs.spaces.windowSpaces(w:id()))); hs.spaces.moveWindowToSpace(w:id(), <OTHER_SPACE_ID>); print('after  '..hs.inspect(hs.spaces.windowSpaces(w:id())))"
--
-- If "after" shows the new space id, moveWindowToSpace is fixed -- re-enable the
-- window-mover (cmd+shift+N) using moveWindowToSpace directly:
--
--   function moveFocusedWindowToSpace(spaceNumber)
--       local win = hs.window.focusedWindow()
--       if not win then hs.alert.show("No focused window"); return end
--       local uuid = win:screen():getUUID()
--       local targetId = userSpaceIds(uuid)[spaceNumber]
--       if not targetId then hs.alert.show("No Desktop "..spaceNumber); return end
--       hs.spaces.moveWindowToSpace(win:id(), targetId)
--   end
--   for i = 1, 6 do
--       hs.hotkey.bind({ "cmd", "shift" }, tostring(i), function() moveFocusedWindowToSpace(i) end)
--   end
-- ============================================================================

-- Diagnostic: run `hs -c "dumpSpaces()"` to inspect the raw data.
function dumpSpaces()
    print("allSpaces: " .. hs.inspect(hs.spaces.allSpaces()))
    print("missionControlSpaceNames: " .. hs.inspect(hs.spaces.missionControlSpaceNames()))
    local uuid = hs.screen.mainScreen():getUUID()
    print("userSpaceIds: " .. hs.inspect(userSpaceIds(uuid)))
    print("activeSpaceOnScreen: " .. tostring(hs.spaces.activeSpaceOnScreen(uuid)))
end
