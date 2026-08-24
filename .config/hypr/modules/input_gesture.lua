hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = true,
            disable_while_typing = true,
            scroll_factor = 0.6,
            tap_and_drag = true
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})
hl.gesture({
    fingers = 2,
    direction = "pinch",
    action = "cursorZoom",
    zoom_level = 1,
    mode = "live" })
hl.device({
    name        = "elan1300:00-04f3:3059-touchpad",
    sensitivity = 0.0,
})
