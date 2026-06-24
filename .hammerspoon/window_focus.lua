-- window_focus.lua
-- Move keyboard focus between windows by direction (vim-style):
--   Ctrl+H -> focus the window to the LEFT of the current one
--   Ctrl+L -> focus the window to the RIGHT of the current one
--   Ctrl+J -> focus the window BELOW the current one
--   Ctrl+K -> focus the window ABOVE the current one
--
-- NOTE: these use Option (alt). Hammerspoon grabs the keys before macOS does
-- Option+letter character composition, so it suppresses the special chars those
-- would type (Option+H/J/K/L = ˙ ∆ ˚ ¬). Change the modifier below if needed.

local log = hs.logger.new('WindowFocus', 'info')

local MODS = { "alt" }

-- Focus the nearest window in the given direction from the focused one.
-- signature: focusWindow<Dir>(candidateWindows, frontmost, strict)
-- nil candidates = all windows; frontmost=false; strict=true keeps it to
-- windows actually in that direction (a tighter directional cone).
local function focusDirection(method)
    local win = hs.window.focusedWindow()
    if not win then
        return
    end
    win[method](win, nil, false, true)
end

hs.hotkey.bind(MODS, "h", function() focusDirection("focusWindowWest") end)
hs.hotkey.bind(MODS, "l", function() focusDirection("focusWindowEast") end)
hs.hotkey.bind(MODS, "j", function() focusDirection("focusWindowSouth") end)
hs.hotkey.bind(MODS, "k", function() focusDirection("focusWindowNorth") end)
