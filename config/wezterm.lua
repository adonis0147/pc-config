local wezterm = require 'wezterm'

local config = wezterm.config_builder()

config.audible_bell = 'Disabled'

config.enable_tab_bar = false

config.color_scheme = 'Monokai (dark) (terminal.sexy)'

config.font = wezterm.font_with_fallback {
	'SF Mono',
	'PingFang SC',
}
config.font_size = 16.0

return config
