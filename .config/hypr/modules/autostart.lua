-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
-- Set programs that you use

local settings = require("modules.settings")

hl.on("hyprland.start", function () 
    --hl.exec_cmd("hyprpm reload -n && hyprctl eval 'hl.monitor({ output = \"eDP-1\", disabled = false, mode = \"preferred\", position = \"0x0\", scale = 1.25})'")
    hl.monitor({output = "eDP-1", scale = 1.25})
    hl.exec_cmd("waypaper --fill fill --random")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)

