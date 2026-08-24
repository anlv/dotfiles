local settings = require("modules.settings")

local applying = false          -- cờ chặn gọi lặp (chống double-call)
local self_disabling = false    -- đánh dấu: mình vừa chủ động disable external, không phải rút dây thật
local external_connected = false -- trạng thái CẮM THẬT của external, cập nhật qua event

local current_mode = "both"     -- "laptop" | "external" | "both" -- mode đang active, dùng để bắt cửa sổ lạc sang eDP-1 khi nó bị DPMS-off

-- Seed trạng thái lúc load config (hl.get_monitors() an toàn, không phải io.popen)
for _, m in pairs(hl.get_monitors()) do
    if m.name == settings.external_mon then
        external_connected = true
    end
end
current_mode = external_connected and "both" or "laptop"

local function get_monitor_name(ws)
    local m = ws.monitor
    if m == nil then return nil end

    return m.name
end

-- Trả về workspace ID nhỏ nhất (>=1) hiện chưa tồn tại. Dùng thay cho việc để
-- Hyprland tự sinh workspace mới, vì mặc định nó không tái sử dụng số nhỏ đã
-- giải phóng mà cứ đẻ ra số lớn tiếp theo (ví dụ 11 khi 1-10 đã "có mặt" ở đâu đó).
local function smallest_free_workspace()
    local used = {}
    for _, ws in pairs(hl.get_workspaces()) do
        used[ws.id] = true
    end
    local n = 1
    while used[n] do
        n = n + 1
    end
    return n
end

-- Đảm bảo monitor_name có ít nhất 1 workspace. Nếu chưa có (monitor vừa được
-- bật/cắm và trống trơn), ép nó nhận workspace trống nhỏ nhất thay vì để
-- Hyprland tự sinh ra 1 số rất lớn.
local function ensure_monitor_has_workspace(monitor_name)
    for _, ws in pairs(hl.get_workspaces()) do
        if get_monitor_name(ws) == monitor_name then
            return -- đã có workspace rồi, khỏi làm gì thêm
        end
    end
    local id = smallest_free_workspace()
    hl.workspace_rule({ workspace = tostring(id), monitor = monitor_name })
    hl.dispatch(hl.dsp.focus({ workspace = id }))
end

local function move_workspaces(from_monitor, to_monitor)
    for _, ws in pairs(hl.get_workspaces()) do
        if get_monitor_name(ws) == from_monitor then
            local ok = pcall(function()
                hl.dispatch(hl.dsp.workspace.move({ workspace = ws.id, monitor = to_monitor }))
            end)
            if not ok then
                -- fallback dùng cú pháp dispatcher kiểu cũ, chạy trực tiếp qua raw string
                hl.dispatch(hl.dsp.exec_raw("moveworkspacetomonitor " .. ws.id .. " " .. to_monitor))
            end
        end
    end
end

local function restart_waybar()
    hl.timer(function()
        hl.dispatch(hl.dsp.exec_cmd("killall -SIGUSR2 waybar"))
    end, { timeout = 400, type = "oneshot" })
end

local function reapply_wallpaper()
    hl.timer(function()
        hl.dispatch(hl.dsp.exec_cmd("waypaper --fill fill --restore"))
    end, { timeout = 500, type = "oneshot" }) -- chờ output mới sẵn sàng trước khi set
end

-- Bọc mọi hàm chuyển chế độ: defer toàn bộ thân hàm qua hl.timer để KHÔNG BAO GIỜ
-- thay đổi trạng thái monitor đồng bộ ngay trong call stack của keybind/event
-- (Hyprland wiki cảnh báo làm vậy có thể gây "undefined behavior", phải reboot cứng).
-- Đồng thời tự mở khóa cờ applying sau khi xong.
local function with_guard(fn)
    return function()
        if applying then return end
        applying = true
        hl.timer(function()
            local ok, err = pcall(fn)
            if not ok then
                hl.notification.create({ text = "Lỗi khi đổi monitor: " .. tostring(err), timeout = 4000 })
            end
            hl.timer(function() applying = false end, { timeout = 1000, type = "oneshot" })
        end, { timeout = 500, type = "oneshot" })
    end
end

local function pin_workspaces_to(monitor_name)
    for i = 1, 10 do
        hl.workspace_rule({ workspace = tostring(i), monitor = monitor_name })
    end
end

local only_laptop = with_guard(function()
    current_mode = "laptop"
    move_workspaces(settings.external_mon, settings.laptop_mon)
    pin_workspaces_to(settings.laptop_mon)
    -- CHỈ chủ động disable external + set cờ self_disabling khi nó THẬT SỰ còn
    -- đang cắm (tức là hàm được gọi vì người dùng bấm phím tắt để ẩn màn ngoài
    -- đi trong khi vẫn cắm dây). Nếu external_connected đã là false (hàm này
    -- đang được gọi PHẢN ỨNG lại từ monitor.removed do rút dây THẬT), tuyệt đối
    -- không được disable nữa, vì:
    --  1) output đã biến mất, hl.monitor({disabled=true}) trên nó không báo lỗi
    --     mà chỉ ÂM THẦM LƯU LẠI 1 rule "disabled=true" áp dụng cho lần sau nó
    --     xuất hiện -> lần cắm lại dây tiếp theo, Hyprland giữ nó tắt ngay từ
    --     đầu -> monitor.added không bao giờ bắn -> external_connected mãi mãi
    --     kẹt ở false, không có cách nào bật lại được nữa.
    --  2) self_disabling sẽ bị set true mà không có monitor.removed thật nào
    --     theo sau để "tiêu" nó về false, làm hỏng logic phân biệt rút dây
    --     thật/giả cho lần rút dây kế tiếp.
    if external_connected then
        self_disabling = true
        hl.monitor({ output = settings.external_mon, disabled = true })
    else
        -- Rút dây thật: external không còn để "disable", nhưng nếu để nguyên rule
        -- vị trí cũ (thường là "0x0", trùng với vị trí laptop) thì lúc cắm lại,
        -- Hyprland có thể tự hồi sinh nó NGAY LẬP TỨC ở vị trí cũ đó -- trước cả
        -- khi hl.on("monitor.added") kịp chạy (bị with_guard delay 500ms) --
        -- khiến nó chồng lên laptop và bắn cảnh báo overlap thoáng qua. Dọn 
        -- trước vị trí "để dành" của nó sang chỗ không đè lên ai, không đụng
        -- tới disabled để tránh lặp lại bug "kẹt disabled vĩnh viễn".
        hl.monitor({ output = settings.external_mon, mode = "preferred", position = "0x-100000" })
    end
    hl.dispatch(hl.dsp.dpms({ action = "enable", monitor = settings.laptop_mon }))
    hl.monitor({ output = settings.laptop_mon, disabled = false, mode = "preferred", position = "0x0", scale = 1.25 })
    ensure_monitor_has_workspace(settings.laptop_mon)
    hl.dispatch(hl.dsp.focus({ monitor = settings.laptop_mon }))
    restart_waybar()
    reapply_wallpaper()
    hl.notification.create({ text = "Monitor: chỉ laptop", timeout = 3000 })
end)

local only_external = with_guard(function()
    if not external_connected then
        hl.notification.create({ text = "Không có màn ngoài nào đang cắm!", timeout = 2500 })
        return
    end
    current_mode = "external"
    pin_workspaces_to(settings.external_mon)
    -- QUAN TRỌNG: bật hẳn external (disabled=false) TRƯỚC khi move workspace sang.
    -- Trước đây move_workspaces() chạy trong lúc external còn đang disabled nên
    -- lệnh move thất bại âm thầm -> external trống -> Hyprland tự sinh workspace
    -- mới với số lớn (ví dụ 11) thay vì dùng lại các workspace nhỏ đã có.
    hl.monitor({ output = settings.external_mon, disabled = false, mode = "preferred", position = "0x0", scale = 1.25 })
    move_workspaces(settings.laptop_mon, settings.external_mon)
    -- Dùng DPMS thay vì disable hẳn eDP-1: laptop vẫn "tồn tại" với compositor
    -- (chỉ tắt hình), nên không bao giờ rơi vào trạng thái 0 output thật sự
    -- nếu lỡ rút external ngay sau đó.
    hl.dispatch(hl.dsp.dpms({ action = "disable", monitor = settings.laptop_mon }))
    -- Đẩy laptop ra xa khỏi layout của external để chuột không lạc sang màn đã tắt
    -- (DPMS chỉ tắt hình, laptop vẫn "tồn tại" trong layout nên mặc định nó nằm sát external)
    hl.monitor({ output = settings.laptop_mon, mode = "preferred", position = "0x-100000", scale = 1.25 })
    -- Lưới an toàn: nếu vì lý do gì đó external vẫn trống (move thất bại, chưa
    -- từng có workspace nào...), ép nó nhận workspace trống nhỏ nhất.
    ensure_monitor_has_workspace(external)
    -- Ép Hyprland coi external là monitor "current": nếu không, workspace mới (chưa
    -- từng tạo) sẽ bị tạo trên eDP-1 (vẫn còn trong layout dù DPMS-off) -> chuyển
    -- workspace trông như "không hoạt động" vì bạn không thấy gì trên màn đã tắt.
    hl.dispatch(hl.dsp.focus({ monitor = settings.external_mon }))
    restart_waybar()
    reapply_wallpaper()
    hl.notification.create({ text = "Monitor: chỉ màn ngoài", timeout = 5000 })
end)

local both_monitors = with_guard(function()
    if not external_connected then
        hl.notification.create({ text = "Không có màn ngoài để hiện cùng lúc", timeout = 2500 })
        return
    end
    hl.dispatch(hl.dsp.dpms({ action = "enable", monitor = settings.laptop_mon }))
    hl.monitor({ output = settings.laptop_mon, disabled = false, mode = "preferred", position = "0x0", scale = 1.25 })
    hl.monitor({ output = settings.external_mon, disabled = false, mode = "preferred", position = "auto-up", scale = 1.25 })
    -- Nếu external vừa được bật/cắm lần đầu và chưa từng có workspace nào, ép nó
    -- nhận workspace trống nhỏ nhất thay vì để Hyprland tự sinh số lớn (vd 11).

    current_mode = "both"
    ensure_monitor_has_workspace(settings.external_mon)

    restart_waybar()
    reapply_wallpaper()
    hl.notification.create({ text = "Monitor: cả 2 màn", timeout = 2000 })
end)

hl.on("monitor.added", function(m)
    if m.name == settings.external_mon then
        external_connected = true
        both_monitors()
        hl.notification.create({ text = "Monitor: ADDED: ".. settings.external_mon, timeout = 2000 })
    end
end)

hl.on("monitor.removed", function(m)
    if m.name == settings.external_mon then
        if self_disabling then
            -- Do chính only_laptop() gây ra (mình chủ động tắt), không phải rút dây thật
            self_disabling = false
        else
            external_connected = false
            only_laptop()
            hl.notification.create({ text = "Monitor: REMOVED: ".. settings.external_mon, timeout = 2000 })
        end
    end
    -- Safety-net: nếu sau sự kiện này không còn output nào active, tự cứu bằng cách bật lại laptop
    hl.timer(function()
        local active = hl.get_monitors()
        if #active == 0 then
            hl.dispatch(hl.dsp.dpms({ action = "enable", monitor = settings.laptop_mon }))
            hl.monitor({ output = settings.laptop_mon, disabled = false, mode = "preferred", position = "0x0", scale = 1.25 })
            restart_waybar()
            reapply_wallpaper()
            hl.notification.create({ text = "Đã tự bật lại laptop vì mất hết màn hình", timeout = 4000 })
        end
    end, { timeout = 150, type = "oneshot" })
end)

-- Vì only_external() chỉ DPMS-off laptop (không disable hẳn), eDP-1 vẫn tồn tại
-- thật sự trong layout của Hyprland. Do đó bất kỳ cửa sổ nào bị app/rule/hyprland
-- tự gán vào workspace của eDP-1 sau khi đã chuyển mode (dialog con, cửa sổ mới
-- của app đang chạy, workspace chưa kịp pin...) sẽ "biến mất" vì màn đó đang tắt
-- hình, thay vì tự trôi sang external. Bắt sự kiện window.open để tự kéo nó sang.
local function move_window_to_monitor(w, to_monitor)
    local ok = pcall(function()
        hl.dispatch(hl.dsp.window.move({ window = "address:" .. tostring(w.address), monitor = to_monitor }))
    end)
    if not ok then
        hl.dispatch(hl.dsp.exec_raw("movewindow mon:" .. to_monitor))
    end
end

hl.on("window.open", function(w)
    if current_mode ~= "external" then return end
    if not w or get_monitor_name(w) ~= settings.laptop_mon then return end
    -- defer 1 nhịp: lúc window.open bắn ra window có thể chưa map hẳn vào layout
    hl.timer(function()
        local ok, err = pcall(function()
            move_window_to_monitor(w, settings.external_mon)
            hl.dispatch(hl.dsp.focus({ monitor = settings.external_mon }))
        end)
        if not ok then
            hl.notification.create({ text = "Lỗi khi kéo cửa sổ lạc sang màn ngoài: " .. tostring(err), timeout = 3000 })
        end
    end, { timeout = 30, type = "oneshot" })
end)
-- Multimonitor key


hl.bind( "SUPER + ALT + 1", only_laptop)
hl.bind( "SUPER + ALT + 2", only_external)
hl.bind( "SUPER + ALT + 3", both_monitors)
hl.bind( "SUPER + ALT + 0", function()
    applying = false
    hl.notification.create({ text = "Đã reset guard chuyển màn hình", timeout = 1500 })
end)

