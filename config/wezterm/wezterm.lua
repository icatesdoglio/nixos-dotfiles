local wezterm = require "wezterm"

local config = wezterm.config_builder()

config.default_prog = { "/usr/bin/env", "bash" , "-l" }

config.color_scheme = "tokyonight"



config.font = wezterm.font("JetBrainsMono Nerd Font Mono")

config.font_size = 11

config.use_fancy_tab_bar = false

config.window_padding = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
}

config.window_background_opacity = 0.8
config.text_background_opacity = 0.8

local function adjust_opacity(window, pane, delta)
  local overrides = window:get_config_overrides() or {}
  local opacity = overrides.window_background_opacity
    or config.window_background_opacity
    or 1.0

  opacity = opacity + delta
  if opacity < 0.1 then opacity = 0.1 end
  if opacity > 1.0 then opacity = 1.0 end

  overrides.window_background_opacity = opacity
  overrides.text_background_opacity = opacity
  window:set_config_overrides(overrides)
end

config.keys = {
    {
        key = "[",
        mods = "ALT",
        action = wezterm.action_callback(function(win, pane)
            adjust_opacity(win, pane, -0.05)
        end),
    },
    {
        key = "]",
        mods = "ALT",
        action = wezterm.action_callback(function(win, pane)
            adjust_opacity(win, pane, 0.05)
        end),
    },

}

config.adjust_window_size_when_changing_font_size = false;



return config
