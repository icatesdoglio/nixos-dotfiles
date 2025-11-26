local wezterm = require "wezterm"

local config = wezterm.config_builder()

config.color_scheme = "tokyonight"

config.font = wezterm.font("Inconsolata Nerd Font Mono")

config.font_size = 13

config.use_fancy_tab_bar = false

config.window_padding = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
}


config.default_prog = { "/home/ian/.nix-profile/bin/nu" }

return config
