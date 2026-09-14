-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
-- Set programs that you use

local settings = require("modules.settings")

local function focus_or_open_browser(keyword, browser_cmd)
    local all_windows = hl.get_windows()
    local found = false

    for _, win in pairs(all_windows) do
        if win.title and string.find(win.title, keyword) then
            -- Tìm thấy -> focus
            hl.dispatch(hl.dsp.focus({ window = win }))
            found = true
            break  -- chỉ focus cửa sổ đầu tiên tìm thấy
        end
    end

    if not found then
        -- Không tìm thấy -> mở trình duyệt
        hl.dispatch(hl.dsp.exec_cmd(browser_cmd))
    end
end


-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(settings.mainMod .. " + Q", hl.dsp.exec_cmd(settings.terminal), { submap_universal = true })
local closeWindowBind = hl.bind(settings.mainMod .. " + C", hl.dsp.window.close(), { submap_universal = true })
-- closeWindowBind:set_enabled(false)

-- Kích hoạt submap xác nhận thoát khi bấm Mod + M
hl.bind(settings.mainMod .. " + M", hl.dsp.submap("shutdown_confirm_S_Y_N"))

hl.define_submap("shutdown_confirm_S_Y_N", function()
    -- Bấm Y để thực hiện lệnh thoát máy/tắt Hyprland
    hl.bind("Y", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
    hl.bind("S", hl.dsp.exec_cmd("shutdown now"))
    -- Bấm Escape hoặc N để hủy và quay về trạng thái bình thường
    hl.bind("escape", hl.dsp.submap("reset"))
    hl.bind("N", hl.dsp.submap("reset"))
end)

-- hl.bind(settings.mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"), { submap_universal = true })
hl.bind(settings.mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(settings.mainMod .. " + E", hl.dsp.exec_cmd(settings.fileManager))
hl.bind(settings.mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }), { submap_universal = true })
hl.bind(settings.mainMod .. " + V", hl.dsp.exec_cmd("cliphist list | wofi --dmenu --allow-images -i --pre-display-cmd \"echo '%s' | cut -f 2\" | cliphist decode | wl-copy"), { submap_universal = true }) 

hl.bind(settings.mainMod .. " + H", hl.dsp.exec_cmd("killall -SIGUSR1 waybar"))
hl.bind("code:49"                 , hl.dsp.exec_cmd(settings.menu))
hl.bind(settings.mainMod .. " + B", hl.dsp.exec_cmd(settings.browser))
hl.bind(settings.mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(settings.mainMod .. " + J", hl.dsp.layout("togglesplit"))    -- dwindle only

hl.bind(settings.mainMod .. " + F", hl.dsp.window.fullscreen_state({ internal = 2, client = 0, action = "toggle" }))


hl.bind("F1", function()
    focus_or_open_browser("% ", settings.browser)
end
)

-- Screenshot
hl.bind(settings.mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m window --clipboard-only"))
hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -m output --clipboard-only"))
hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd("hyprshot -m region --clipboard-only"))

-- Move focus with mainMod + arrow keys
hl.bind(settings.mainMod .. " + left",  hl.dsp.focus({ direction = "left" }), { submap_universal = true })
hl.bind(settings.mainMod .. " + right", hl.dsp.focus({ direction = "right" }), { submap_universal = true })
hl.bind(settings.mainMod .. " + up",    hl.dsp.focus({ direction = "up" }), { submap_universal = true })
hl.bind(settings.mainMod .. " + down",  hl.dsp.focus({ direction = "down" }), { submap_universal = true })

hl.bind(settings.mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }), { submap_universal = true })
hl.bind(settings.mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }), { submap_universal = true })
hl.bind(settings.mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }), { submap_universal = true })
hl.bind(settings.mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }), { submap_universal = true })
-- Switch workspaces with settings.mainMod + [0-9]
-- Move active window to a workspace with settings.mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(settings.mainMod .. " + " .. key,  hl.dsp.focus({ workspace = i}), { submap_universal = true })
    hl.bind(settings.mainMod .. " + CTRL + "  .. key,     hl.dsp.focus({ workspace = i, on_current_monitor = true}), { submap_universal = true })
    hl.bind(settings.mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }), { submap_universal = true })
end

-- Example special workspace (scratchpad)
hl.bind(settings.mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"), { submap_universal = true })
hl.bind(settings.mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic", follow = false }), { submap_universal = true })

-- Scroll through existing workspaces with settings.mainMod + scroll
hl.bind(settings.mainMod .. "+ CTRL + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { submap_universal = true })
hl.bind(settings.mainMod .. "+ CTRL + mouse_up",   hl.dsp.focus({ workspace = "e-1" }), { submap_universal = true })

hl.bind(settings.mainMod .. "+ CTRL + left",  hl.dsp.focus({ workspace = "e-1" }), { submap_universal = true })
hl.bind(settings.mainMod .. "+ CTRL + right", hl.dsp.focus({ workspace = "e+1" }), { submap_universal = true })
-- Move/resize windows with settings.mainMod + LMB/RMB and dragging
hl.bind(settings.mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true, submap_universal = true })
hl.bind(settings.mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, submap_universal = true })

hl.bind(settings.mainMod .. " + equal", hl.dsp.layout("colresize +conf"), {  submap_universal = true })
hl.bind(settings.mainMod .. " + minus", hl.dsp.layout("colresize -conf"), {  submap_universal = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })

-- Activate resize submap with Mod + R
hl.bind(settings.mainMod .. " + R", hl.dsp.submap("resize"))

hl.define_submap("resize", function()
    -- Arrow keys to resize with 10px steps (repeatable)
    hl.bind("right", hl.dsp.window.resize({ x = 15, y = 0, relative = true }), { repeating = true })
    hl.bind("left", hl.dsp.window.resize({ x = -15, y = 0, relative = true }), { repeating = true })
    hl.bind("up", hl.dsp.window.resize({ x = 0, y = -15, relative = true }), { repeating = true })
    hl.bind("down", hl.dsp.window.resize({ x = 0, y = 15, relative = true }), { repeating = true })
    -- Escape to exit submap
    hl.bind("escape", hl.dsp.submap("reset"))
end)


hl.on("window.active", function(window)
    --hl.notification.create({text = window.class,  timeout = 7000, font_size = 20})
    if window and window.class and window.class:match("01KZAYRZ") then
        hl.dispatch(hl.dsp.submap("tradingview"))
    else
        hl.dispatch(hl.dsp.submap("reset"))
    end
end)
hl.on("window.close", function(window)
    if window and window.class and window.class:match("01KZAYRZ") then
        hl.timer(function()
            if #hl.get_workspace_windows(hl.get_active_workspace().name) == 0 then
                -- Actions to perform when NO windows are open
                -- hl.notification.create({text = "reset submap tradingview",  timeout = 7000, font_size = 20})
                hl.dispatch(hl.dsp.submap("reset"))

            end
        end, {timeout = 200, type = "oneshot"})

    end
end)

-- Bind Right Control to dispatch a Page Down keypress

-- Bắt sự kiện NHẢ nút Right Control và CHỈ gửi phím Page Down thuần túy

hl.define_submap("tradingview", function()

    hl.bind("Control_R",
        hl.dsp.send_shortcut({ mods = "", key = "next" }), {
            ignore_mods = true,
        }
    )
    hl.bind("Alt_R", 

        hl.dsp.send_shortcut({ mods = "", key = "prior" }), {
            ignore_mods = true,

        }
    )
    hl.bind("PAUSE",

        hl.dsp.send_shortcut({ mods = "", key = "Scroll_Lock" }), {
            ignore_mods = true
        }
    )

    -- Escape to exit submap
end)
        
local function testLua()

    local handle = io.popen("/home/anlv/.config/hypr/Scripts/get_quote.sh")
    local result = handle:read("*a")
    handle:close()
    result=result:gsub("%s+$","")

    local esc_result = result:gsub('"', '\\"')

    hl.dispatch(hl.dsp.exec_cmd('notify-send -t 0 -h string:bgcolor:#4444ff "" "<span size=\'14000\'>' .. esc_result ..  '<br></span>"' ))

end

hl.bind("SUPER + SHIFT + T", testLua)
