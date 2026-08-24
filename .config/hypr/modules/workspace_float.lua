-- workspace_float.lua
-- Toggle giữa "workspace floating" và "workspace tiled"

local floatState = {}   -- [workspaceId] = true/false
local floatRule  = {}   -- [workspaceId] = rule_handle

local function setWorkspaceFloat(isFloat)
    local aw = hl.get_active_window()
    if aw == nil then return end

    local wsId = aw.workspace.id
    local newState = isFloat
    floatState[wsId] = newState
    local foo = nil
    if newState == true then
        foo = "on"
    else
        foo = "off"
    end


    -- 1) Xử lý các cửa sổ ĐANG MỞ trên workspace này
    for _, w in pairs(hl.get_windows()) do
        if w.workspace ~= nil and w.workspace.id == wsId then
            if w.floating ~= newState then
                hl.dispatch(hl.dsp.window.float({
                    action = foo,
                    window = "address:" .. w.address,
                }))
            end
        end
    end

    -- 2) Rule để CỬA SỔ MỚI mở trên workspace này cũng theo đúng trạng thái
    if floatRule[wsId] == nil then
        floatRule[wsId] = hl.window_rule({
            name  = "auto-float-ws-" .. wsId,
            match = { workspace = tostring(wsId) },
            float = true,
        })
    end
    floatRule[wsId]:set_enabled(newState)
end

hl.bind("ALT + Tab", function()
    setWorkspaceFloat(true)
    hl.dispatch(hl.dsp.window.cycle_next({ next = true, floating = true }))
    hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
end, { submap_universal = true })

hl.bind("SUPER + D", function()

    local aw = hl.get_active_window()
    if aw == nil then return end


    local ws = hl.get_active_workspace()
    if ws == nil then return end

    local windows = ws:get_windows()
    if #windows == 0 then return end

    local mon = ws.monitor

    -- lấy reserved area qua hyprctl CLI (mon.reserved không có sẵn trong Lua API)
    local gaps_out = hl.get_config("general.gaps_out")
    local gaps_in  = hl.get_config("general.gaps_in")
    local waybar_height = hl.get_active_monitor().reserved.top

    local left, top, right, bottom = gaps_out.left + gaps_in.left, gaps_out.top + gaps_in.top, gaps_out.right + gaps_in.right , gaps_out.bottom + gaps_in.bottom

    local monW = mon.width / mon.scale
    local monH = mon.height / mon.scale

    -- maximized size
    local targetX = mon.x + left
    local targetY = mon.y + top + waybar_height
    local targetW = monW - left - right
    local targetH = monH - top - bottom - waybar_height
    
    -- set floating

    hl.dispatch(hl.dsp.window.float({
        action = "on",
        window = "address:" .. aw.address,
    }))

    -- 1. resize (theo delta so với size hiện tại)
    local deltaW = targetW - aw.size.x
    local deltaH = targetH - aw.size.y
    hl.dispatch(hl.dsp.window.resize({ x = targetW, y = targetH,exact = true, window = aw }))

    -- 2. move về đúng góc vùng làm việc (absolute)
    hl.dispatch(hl.dsp.window.move({ x = targetX, y = targetY, window = aw }))
    

end, { submap_universal = true })

hl.bind("SUPER + SHIFT + D", function()
    setWorkspaceFloat(true)
    local ws = hl.get_active_workspace()
    if ws == nil then return end

    local windows = ws:get_windows()
    if #windows == 0 then return end

    local mon = ws.monitor

    -- lấy reserved area qua hyprctl CLI (mon.reserved không có sẵn trong Lua API)
    local gaps_out = hl.get_config("general.gaps_out")
    local gaps_in  = hl.get_config("general.gaps_in")
    local waybar_height = hl.get_active_monitor().reserved.top

    local left, top, right, bottom = gaps_out.left + gaps_in.left, gaps_out.top + gaps_in.top, gaps_out.right + gaps_in.right , gaps_out.bottom + gaps_in.bottom

    local monW = mon.width / mon.scale
    local monH = mon.height / mon.scale

    -- maximized size
    local targetX = mon.x + left
    local targetY = mon.y + top + waybar_height
    local targetW = monW - left - right
    local targetH = monH - top - bottom - waybar_height
    local tempWin = hl.get_active_window()
    -- if maximized size, set to full screen
    if tempWin.size.x == targetW and tempWin.size.y == targetH and tempWin.at.x == targetX and tempWin.at.y == targetY then
        targetH = targetH + waybar_height
        targetY = targetY - waybar_height
    end
    for _, w in ipairs(windows) do

        -- 1. resize (theo delta so với size hiện tại)
        local deltaW = targetW - w.size.x
        local deltaH = targetH - w.size.y
        hl.dispatch(hl.dsp.window.resize({ x = targetW, y = targetH,exact = true, window = w }))

        -- 2. move về đúng góc vùng làm việc (absolute)
        hl.dispatch(hl.dsp.window.move({ x = targetX, y = targetY, window = w }))
    end
end, { submap_universal = true })

local function toggleWorkspaceFloat()
    
    local aw = hl.get_active_window()
    if aw == nil then return end

    local wsId = aw.workspace.id
    local newState = not floatState[wsId]
    floatState[wsId] = newState

    -- 1) Xử lý các cửa sổ ĐANG MỞ trên workspace này
    for _, w in pairs(hl.get_windows()) do
        if w.workspace ~= nil and w.workspace.id == wsId then
            if w.floating ~= newState then
                hl.dispatch(hl.dsp.window.float({
                    action = "toggle",
                    window = "address:" .. w.address,
                }))
            end
        end
    end

    -- 2) Rule để CỬA SỔ MỚI mở trên workspace này cũng theo đúng trạng thái
    if floatRule[wsId] == nil then
        floatRule[wsId] = hl.window_rule({
            name  = "auto-float-ws-" .. wsId,
            match = { workspace = tostring(wsId) },
            float = true,
        })
    end
    floatRule[wsId]:set_enabled(newState)

    hl.notification.create({
        text = "Workspace " .. wsId .. ": " .. (newState and "FLOATING" or "TILED"),
        timeout = 5000,
    })
end

hl.bind("SUPER + SHIFT + F", toggleWorkspaceFloat)

local function serializeTable(val, name, skipnewlines, depth)
    skipnewlines = skipnewlines or false
    depth = depth or 0

    local tmp = string.rep(" ", depth)

    if name then tmp = tmp .. name .. " = " end

    if type(val) == "table" then
        tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

        for k, v in pairs(val) do
            tmp =  tmp .. serializeTable(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
        end

        tmp = tmp .. string.rep(" ", depth) .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
    else
        tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
    end

    return tmp
end



