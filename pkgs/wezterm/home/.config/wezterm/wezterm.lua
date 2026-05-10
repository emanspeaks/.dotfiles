local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.font = wezterm.font 'AtkynsonMono Nerd Font'
config.font_size = 10.0

config.color_scheme = 'MaterialDark'

config.window_padding = {
  left = 4,
  right = 20,
  top = 4,
  bottom = 4,
}

config.initial_cols = 220
config.initial_rows = 50
config.enable_scroll_bar = true

--config.use_fancy_tab_bar = false
--config.tab_bar_at_bottom = true

-- SSH Quick Connect (Ctrl+Shift+S)
-- Prompts for a host name and opens it in a new tab.
-- Reads your ~/.ssh/config so just type the Host alias.
config.keys = {
  {
    key = 's',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.PromptInputLine {
      description = 'SSH host:',
      action = wezterm.action_callback(function(window, pane, line)
        if line and line ~= '' then
          window:perform_action(
            wezterm.action.SpawnCommandInNewTab {
              args = { 'ssh', line },
            },
            pane
          )
        end
      end),
    },
  },
}

config.mouse_bindings = {
  {
    event = { Down = { streak = 1, button = 'Right' } },
    mods = 'NONE',
    action = wezterm.action.PasteFrom 'Clipboard',
  },
}

config.visual_bell = {
  fade_in_function = 'EaseIn',
  fade_in_duration_ms = 150,
  fade_out_function = 'EaseOut',
  fade_out_duration_ms = 150,
}
config.colors = {
  visual_bell = '#202020',
  scrollbar_thumb = '#444444',
}

config.exit_behavior = 'Hold'

config.default_prog = { 'C:\\msys64\\msys2_shell.cmd', '-defterm', '-no-start', '-ucrt64' }

return config
