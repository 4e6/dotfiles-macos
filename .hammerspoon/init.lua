-- ~/.hammerspoon/init.lua
-- Entry point for the Hammerspoon configuration.

-- Enable the `hs` command-line tool (lets us run `hs -c "..."` from a terminal)
require("hs.ipc")

-- Desktop switching (ctrl + 1-6 jumps to a desktop). Also documents the
-- still-broken "move window to a desktop" feature as a ticket to revisit.
require("spaces")

-- Directional window focus (cmd+h / cmd+l -> focus window left / right)
require("window_focus")

-- Keyboard backlight step controls (Command+F1 / Command+F2)
require("keyboard_backlight")

hs.alert.show("Hammerspoon config loaded")
