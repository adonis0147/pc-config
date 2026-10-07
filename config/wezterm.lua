local wezterm = require "wezterm"
local function latest_node()
	local nodes =
		wezterm.glob(
			wezterm.home_dir .. "/.local/share/zinit/plugins/nvm/versions/node/*/bin/node"
		)
	table.sort(nodes, function(a, b)
		local left = { a:match("/v(%d+)%.(%d+)%.(%d+)/bin/node$") }
		local right = { b:match("/v(%d+)%.(%d+)%.(%d+)/bin/node$") }
		for i = 1, 3 do
			if tonumber(left[i]) ~= tonumber(right[i]) then
				return tonumber(left[i]) > tonumber(right[i])
			end
		end
		return false
	end)
	if nodes[1] then
		return nodes[1]
	end
	local windows = wezterm.target_triple:find("windows", 1, true)
	local separator = windows and ";" or ":"
	local path = os.getenv("PATH") or ""
	if wezterm.target_triple:find("apple", 1, true) then
		path = path .. ":/opt/homebrew/bin:/usr/local/bin"
	end
	for directory in path:gmatch("[^" .. separator .. "]+") do
		local candidate = directory .. (windows and "/node.exe" or "/node")
		local file = io.open(candidate, "rb")
		if file then
			file:close()
			return candidate
		end
	end
end

local node = latest_node()
if node then
	local bridge =
		dofile(
			wezterm.home_dir .. "/.config/pi-config/src/extensions/clipboard-image/wezterm.lua"
		)
	bridge.setup {
		helper = wezterm.home_dir .. "/.config/pi-config/src/extensions/clipboard-image/macos-helper.ts",
		node = node,
	}
end

local get_os_type = function()
	local patterns = { "%-apple%-", "%-linux%-", "%-windows%-" }
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
	config.audible_bell = "Disabled"
	config.enable_tab_bar = false
	config.window_padding = {
		left = 0,
		right = 0,
		top = 0,
		bottom = 0,
	}
	config.color_scheme = "Monokai (dark) (terminal.sexy)"
	config.font_size = 16.0
end

local setup_for_apple = function(config)
	config.font = wezterm.font_with_fallback { "SF Mono", "PingFang SC" }
end

local setup_for_windows = function(config)
	for _, domain in ipairs(wezterm.default_wsl_domains()) do
		config.default_domain = domain.name
		break
	end
end

local setup_for_specific_os = function(config)
	local os_type = get_os_type()
	if os_type == "apple" then
		setup_for_apple(config)
	elseif os_type == "windows" then
		setup_for_windows(config)
	end
end

local config = wezterm.config_builder()

setup_common(config)
setup_for_specific_os(config)

return config
