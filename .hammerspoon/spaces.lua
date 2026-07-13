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
--   * BACK-AND-FORTH: pressing Option+<number> while ALREADY on Desktop N jumps
--     back to the desktop you were on previously (like i3's `workspace
--     back_and_forth`) instead of doing nothing. "Previously" tracks ALL desktop
--     changes -- Option+N, native Ctrl+N, trackpad swipes, Mission Control -- via
--     an hs.spaces.watcher. See currentDesktopNumber()/switchOrToggleDesktop() and
--     the currentDesktop/previousDesktop state below.
--   * Desktop 10 is keyed to 0 (Option+0), mirroring how macOS numbers the
--     digit row 1..9,0. IMPORTANT: macOS only AUTO-binds Ctrl+1..Ctrl+9; it does
--     NOT assign Ctrl+0 to "Switch to Desktop 10". So Option+0 stays a no-op
--     until you map it once by hand: System Settings -> Keyboard -> Keyboard
--     Shortcuts -> Mission Control -> "Switch to Desktop 10" = Ctrl+0.
--
-- MOVING THE FOCUSED WINDOW:
--   * Option+Shift+<number> -> move the focused window to Desktop N and follow
--     it there. See moveFocusedWindowToSpace() below. hs.spaces.moveWindowToSpace
--     is broken on macOS 15+/26 (GitHub issue #3698), so this uses the community
--     drag workaround: hold the title bar, fire the native Ctrl+N switch, the
--     held window comes along.
--
-- TRADE-OFF: binding Option+<number> means you can no longer TYPE the
-- Option+digit special characters (¡ ™ £ ¢ ∞ §, plus Option+0 = º) -- Hammerspoon consumes those
-- keystrokes. (Likewise the directional-focus binds in window_focus.lua claim
-- Option+H/J/K/L = ˙ ∆ ˚ ¬.) Rarely an issue; switch SWITCH_MODS if it is.

local log = hs.logger.new('Spaces', 'info')

local DESKTOPS_NUMBER = 10             -- Number of desktops
local SWITCH_MODS = { "alt" }          -- Option+N      -> switch to Desktop N
local MOVE_MODS   = { "alt", "shift" } -- Option+Shift+N -> move window to Desktop N

-- The key (and native Ctrl+key shortcut) for a desktop number. Desktops 1-9 use
-- their own digit; Desktop 10 uses "0" (10 % 10 == 0), matching macOS, which
-- numbers the row of digit keys 1..9,0.
local function desktopKey(spaceNumber)
    return tostring(spaceNumber % 10)
end

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

-- Current desktop NUMBER (1-based), found by locating the active space in the
-- ordered userSpaceIds list. Returns nil if the active space is a full-screen-app
-- space (skipped by userSpaceIds) -- callers then fall back to a plain switch.
local function currentDesktopNumber()
    local uuid = hs.screen.mainScreen():getUUID()
    local active = hs.spaces.activeSpaceOnScreen(uuid)
    for i, spaceId in ipairs(userSpaceIds(uuid)) do
        if spaceId == active then return i end
    end
    return nil
end

-- Back-and-forth state. currentDesktop is the last-known active desktop number;
-- previousDesktop is the one we were on before it. Kept in sync across ALL space
-- changes (hotkeys, native Ctrl+N, swipes, Mission Control) by the watcher below.
local currentDesktop  = currentDesktopNumber()
local previousDesktop = nil

-- 'spaceWatcher' is intentionally GLOBAL: a local would be garbage-collected and
-- the watcher would silently stop firing. On every space change, remember the
-- desktop we just left so Option+N can jump back to it.
spaceWatcher = hs.spaces.watcher.new(function()
    local now = currentDesktopNumber()
    if now and now ~= currentDesktop then
        previousDesktop = currentDesktop
        currentDesktop  = now
    end
end)
spaceWatcher:start()

-- Switch to a desktop number (1-based) by synthesizing the native, fast
-- Ctrl+<number> "Switch to Desktop N" shortcut.
function switchToDesktop(spaceNumber)
    local key = desktopKey(spaceNumber)
    hs.eventtap.event.newKeyEvent({ "ctrl" }, key, true):post()
    hs.eventtap.event.newKeyEvent({ "ctrl" }, key, false):post()
end

-- Option+N handler: switch to Desktop N, but if we're ALREADY on N, toggle back
-- to the previously-active desktop (i3-style back_and_forth).
function switchOrToggleDesktop(n)
    local current = currentDesktopNumber() -- live & authoritative for the decision
    -- Self-heal: if the watcher missed a change, reconcile so previousDesktop is
    -- correct even when the toggle is the first thing we hear about that change.
    if current and current ~= currentDesktop then
        previousDesktop, currentDesktop = currentDesktop, current
    end
    if current == n and previousDesktop and previousDesktop ~= n then
        switchToDesktop(previousDesktop) -- already on N -> go back
    else
        switchToDesktop(n)               -- normal switch (no-op if on N w/o history)
    end
    -- The watcher updates currentDesktop/previousDesktop once the switch lands.
end

-- Bind Option + 1-DESKTOPS_NUMBER to switch desktops (Option+0 -> Desktop 10).
for i = 1, DESKTOPS_NUMBER do
    hs.hotkey.bind(SWITCH_MODS, desktopKey(i), function() switchOrToggleDesktop(i) end)
end

-- ============================================================================
-- TICKET: moving a window between desktops -- broken API + workaround in use
--
-- THE ISSUE (upstream: https://github.com/Hammerspoon/hammerspoon/issues/3698)
--   hs.spaces.moveWindowToSpace(window, spaceId) is broken on macOS 15 Sequoia
--   and 26 Tahoe: it returns `true` but the window never actually changes space.
--   Apple changed the private SkyLight API Hammerspoon drives. Confirmed on this
--   machine -- the call is a silent no-op. Related: gotoSpace() while holding a
--   window does NOT carry it, and synthetic Ctrl+Arrow "move a space" events are
--   ignored entirely.
--
-- THE WORKAROUND (moveFocusedWindowToSpace below; from the #3698 thread)
--   Reproduce the manual gesture: press-and-hold the window's title bar with a
--   synthetic mouse-down, then fire the native, fast "Switch to Desktop N"
--   (Ctrl+N) while holding. The held window rides along to the new desktop. The
--   trigger is Option+Shift+N, so those modifiers are physically down -- a
--   modified click (Option/Shift+click) won't start a window drag, so we release
--   them first and clear the flags on the synthetic mouse events.
--
-- CURRENT LIMITATIONS of the workaround
--   1. It FOLLOWS the window: you end up on the destination desktop (the native
--      Ctrl+N switch moves your view too). It does not "send and stay".
--   2. Existing desktops only: Ctrl+N is a no-op for a desktop that doesn't
--      exist yet, so Option+Shift+3 does nothing until Desktop 3 is created.
--   3. Unreliable for apps whose title bar is interactive -- e.g. Chrome (the
--      grab lands on a TAB, not draggable chrome) and similar tab-strip apps.
--      The window may not get picked up and stays put. Standard title-bar apps
--      (Finder, native apps, terminals) work reliably.
--   4. Same-screen only / not multi-monitor aware: it doesn't target a specific
--      screen's desktop, just whatever Ctrl+N maps to. (Note: moving a window to
--      a space on a DIFFERENT screen is one case where the broken native API
--      reportedly still works -- see irobertson's comment in #3698 if multi-
--      monitor support is needed later.)
--   5. It's a simulated drag with fixed sleeps (~210ms total). Heavy system load
--      could in theory race the timing; bump the usleep values if it gets flaky.
--   6. Briefly hijacks the real mouse cursor (moved to the title bar and back).
--
-- RE-TEST the clean API after any macOS/Hammerspoon update -- if "after" shows
-- the new space id, delete this workaround and just call moveWindowToSpace:
--   hs -c "local w=hs.window.focusedWindow(); print('before '..hs.inspect(hs.spaces.windowSpaces(w:id()))); hs.spaces.moveWindowToSpace(w:id(), <OTHER_SPACE_ID>); print('after  '..hs.inspect(hs.spaces.windowSpaces(w:id())))"
-- Env when written: macOS 26.5.1 (25F80), Hammerspoon 1.1.1, 2026-06-24.
-- ============================================================================

-- Move the focused window to a desktop number (1-based) and follow it there.
function moveFocusedWindowToSpace(spaceNumber)
    local win = hs.window.focusedWindow()
    if not win then
        hs.alert.show("No focused window")
        return
    end

    local et = hs.eventtap.event

    -- Release the held trigger modifiers so the grab is a plain click.
    et.newKeyEvent("alt", false):post()
    et.newKeyEvent("shift", false):post()
    hs.timer.usleep(20000)

    local f = win:frame()
    -- Grab the spot between the red close button and the yellow minimize
    -- button on the window top left. Fixes the issue with moving applications
    -- with busy title bar. For example the Chrome bar can be full of tabs.
    local grab = { x = f.x + 30, y = f.y + 11 }
    local origMouse = hs.mouse.absolutePosition()

    hs.mouse.absolutePosition(grab)
    et.newMouseEvent(et.types.leftMouseDown, grab):setFlags({}):post()
    hs.timer.usleep(40000)
    -- Native fast "Switch to Desktop N"; the held window comes along.
    hs.eventtap.keyStroke({ "ctrl" }, desktopKey(spaceNumber), 0)
    hs.timer.usleep(150000)
    et.newMouseEvent(et.types.leftMouseUp, grab):setFlags({}):post()
    hs.mouse.absolutePosition(origMouse)
end

-- Bind Option+Shift + 1-DESKTOPS_NUMBER to move the focused window to that
-- desktop (Option+Shift+0 -> Desktop 10).
for i = 1, DESKTOPS_NUMBER do
    hs.hotkey.bind(MOVE_MODS, desktopKey(i), function() moveFocusedWindowToSpace(i) end)
end

-- Diagnostic: run `hs -c "dumpSpaces()"` to inspect the raw data.
function dumpSpaces()
    print("allSpaces: " .. hs.inspect(hs.spaces.allSpaces()))
    print("missionControlSpaceNames: " .. hs.inspect(hs.spaces.missionControlSpaceNames()))
    local uuid = hs.screen.mainScreen():getUUID()
    print("userSpaceIds: " .. hs.inspect(userSpaceIds(uuid)))
    print("activeSpaceOnScreen: " .. tostring(hs.spaces.activeSpaceOnScreen(uuid)))
    print("currentDesktopNumber: " .. tostring(currentDesktopNumber()))
    print("tracked currentDesktop: " .. tostring(currentDesktop) ..
          ", previousDesktop: " .. tostring(previousDesktop))
end
