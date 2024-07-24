local wezterm = require 'wezterm'

local get_os_type = function()
	local patterns = { '%-apple%-', '%-linux%-', '%-windows%-' }
	local type = nil
	for _, pattern in ipairs(patterns) do
		local s, e = string.find(wezterm.target_triple, pattern)
		if s ~= nil and e ~= nil then
			return string.sub(wezterm.target_triple, s + 1, e - 1)
		end
	end
	return type
end

local setup_common = function(config)
	config.audible_bell   = 'Disabled'
	config.enable_tab_bar = false
	config.color_scheme   = 'Monokai (dark) (terminal.sexy)'
	config.font_size      = 16.0
end

local setup_for_apple = function(config)
	config.font = wezterm.font_with_fallback {
		'SF Mono',
		'PingFang SC',
	}
end

local setup_for_windows = function(config)
	for _, domain in ipairs(wezterm.default_wsl_domains()) do
		config.default_domain = domain.name
		break
	end
end

local setup_for_specific_os = function(config)
	local os_type = get_os_type()
	if os_type == 'apple' then
		setup_for_apple(config)
	elseif os_type == 'windows' then
		setup_for_windows(config)
	end
end


local config = wezterm.config_builder()

setup_common(config)
setup_for_specific_os(config)

return config
