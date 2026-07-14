-- Hyprland Lua config — 1:1 equivalent of hyprland.conf (hyprlang).
-- hyprland.conf is left untouched as a fallback; delete/rename this file to revert.

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("GTK_IM_MODULE", "fcitx")
hl.env("QT_IM_MODULE", "fcitx")
hl.env("XMODIFIERS", "@im=fcitx")

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")


-----------------
---- MONITOR ----
-----------------

-- Monitor + scale. Format: NAME, RESOLUTION@REFRESH, POSITION, SCALE.
-- hl.monitor({ output = "HDMI-A-1", mode = "3840x2160@120", position = "0x0", scale = 2 })


-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    -- desktop setting
    hl.exec_cmd("wayle shell")
    hl.exec_cmd("fcitx5-remote")

    -- x11 config
    hl.exec_cmd([[echo "Xft.dpi: 200" > ~/.Xresources]])
    hl.exec_cmd("xrdb -merge ~/.Xresources")

    -- Bridge the Hyprland session into systemd so xdg-desktop-portal can start
    -- (xdg-desktop-portal >= 1.22 requires graphical-session.target to be active).
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("systemctl --user start hyprland-session.target")

    -- Polkit auth agent: provides GUI password dialogs for pkexec
    -- hl.exec_cmd("sh -c 'sleep 3 && systemctl --user enable --now hyprpolkitagent.service'") --
end)


------------------
---- PROGRAMS ----
------------------

local mainMod     = "SUPER"
local terminal    = "kitty"
local fileManager = "dolphin"
local menu        = "hyprlauncher"
local browser     = "google-chrome-stable"
local editor      = "code"


---------------------
---- KEYBINDINGS ----
---------------------

hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("code"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("hyprshutdown"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen_state({ internal = 2, client = 0, action = "toggle" }))
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd([[grim -g "$(slurp)" "$HOME/$(date +'%y%m%d_%H-%M-%S').png"]]))
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd([[grim "$HOME/$(date +'%y%m%d_%H-%M-%S').png"]]))

-- Switch workspaces with SUPER + [1..0]; move active window with SUPER + SHIFT + [1..0] (0 = ws 10)
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- movetoworkspacesilent 10 (follow = false => don't switch to it)
hl.bind(mainMod .. " + H", hl.dsp.window.move({ workspace = 10, follow = false }))

-- Move / resize windows with SUPER + LMB / RMB drag
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Audio: bindel (repeat + locked) and bindl (locked only)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),        { locked = true, repeating = true })
hl.bind(mainMod .. " + right",  hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind(mainMod .. " + left",   hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),        { locked = true, repeating = true })
hl.bind("XF86AudioMute",    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),   { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })


--------------------------
---- INPUT / GENERAL ----
--------------------------

hl.config({
    input = {
        sensitivity   = -0.4,
        accel_profile = "flat",
        follow_mouse  = 0,
    },

    general = {
        border_size = 2,
        col = {
            active_border = "rgba(00008bff)",
        },
    },

    xwayland = {
        force_zero_scaling = true,
    },
})
