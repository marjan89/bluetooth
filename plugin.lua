---@type PluginDefinition

-- Default configuration
local default_config = {
	connected_icon = "◍",      -- Unicode filled circle for connected device
	disconnected_icon = "○",   -- Unicode empty circle for disconnected device
}

-- Get configuration with fallback to defaults
local function get_config()
	local plugin = bluetooth  -- Plugin is stored in globals with its name
	return plugin and plugin.config or default_config
end

-- Get icon configuration
local function get_icons()
	local config = get_config()
	return config.connected_icon, config.disconnected_icon
end

return {
	metadata = {
		name = "bluetooth",
		version = "1.0.0",
		icon = "󰂯",
		description = "Bluetooth device switcher with connection toggle",
		platforms = { "macos" },
	},

	tasks = {
		toggle = {
			name = "Toggle Bluetooth Device",
			description = "Connect or disconnect paired Bluetooth devices",
			mode = "none",
			exit_on_execute = true,

			item_sources = {
				devices = {
					tag = "bt",

					items = function()
						local devices = require("bluetooth.devices")
						local connected_icon, disconnected_icon = get_icons()
						return devices.get_paired_devices(connected_icon, disconnected_icon)
					end,

					preview = function(item)
						local devices = require("bluetooth.devices")
						local connected_icon, disconnected_icon = get_icons()
						local name = devices.extract_name(item)
						local address = devices.extract_address(item)
						local connected = devices.is_connected(item, connected_icon)

						local status_text = connected and "Connected" or "Disconnected"
						local status_icon = connected and connected_icon or disconnected_icon

						return string.format(
							"%s %s\n\nDevice: %s\nAddress: %s\n\nAction: %s",
							status_icon,
							status_text,
							name,
							address,
							connected and "Disconnect" or "Connect"
						)
					end,

					execute = function(items)
						local devices = require("bluetooth.devices")
						if not items or #items == 0 then
							return "Error: No device selected", 1
						end

						local connected_icon, _ = get_icons()
						local selected = items[1]
						local name = devices.extract_name(selected)
						local address = devices.extract_address(selected)
						local connected = devices.is_connected(selected, connected_icon)

						if address == "" then
							return "Error: Could not extract device address", 1
						end

						-- Toggle connection
						local output, code
						local action
						if connected then
							output, code = devices.disconnect_device(address)
							action = "Disconnected from"
						else
							output, code = devices.connect_device(address)
							action = "Connected to"
						end

						if code ~= 0 then
							return string.format(
								"Error: Failed to %s %s\n%s",
								connected and "disconnect from" or "connect to",
								name,
								output
							), 1
						end

						return string.format("%s: %s", action, name), 0
					end,
				},
			},
		},

		forget = {
			name = "Forget Bluetooth Device",
			description = "Unpair selected Bluetooth device permanently",
			mode = "none",
			exit_on_execute = true,
			execution_confirmation_message = "Are you sure you want to unpair:",

			item_sources = {
				devices = {
					tag = "bt",

					items = function()
						local devices = require("bluetooth.devices")
						local connected_icon, disconnected_icon = get_icons()
						return devices.get_paired_devices(connected_icon, disconnected_icon)
					end,

					preview = function(item)
						local devices = require("bluetooth.devices")
						local connected_icon, disconnected_icon = get_icons()
						local name = devices.extract_name(item)
						local address = devices.extract_address(item)
						local connected = devices.is_connected(item, connected_icon)

						local status_text = connected and "Connected" or "Disconnected"
						local status_icon = connected and connected_icon or disconnected_icon

						return string.format(
							"⚠️  UNPAIR DEVICE\n\n%s %s\n\nDevice: %s\nAddress: %s\n\nWarning: This will permanently unpair the device.\nYou will need to re-pair it to use it again.",
							status_icon,
							status_text,
							name,
							address
						)
					end,

					execute = function(items)
						local devices = require("bluetooth.devices")
						if not items or #items == 0 then
							return "Error: No device selected", 1
						end

						local selected = items[1]
						local name = devices.extract_name(selected)
						local address = devices.extract_address(selected)

						if address == "" then
							return "Error: Could not extract device address", 1
						end

						-- Unpair device using address (more reliable than name)
						local output, code = devices.unpair_device(address)

						if code ~= 0 then
							return string.format(
								"Error: Failed to unpair %s\n%s\n\nNote: --unpair is experimental in blueutil",
								name,
								output
							), 1
						end

						return string.format("Unpaired: %s", name), 0
					end,
				},
			},
		},

		scan = {
			name = "Discover & Pair Devices",
			description = "Continuously scan for unpaired Bluetooth devices and pair them on selection",
			mode = "none",
			exit_on_execute = true,

			-- Rescan every 10 seconds for new devices
			item_polling_interval = 10000,

			-- No preview polling needed (device info is static)
			preview_polling_interval = 0,

			item_sources = {
				devices = {
					tag = "bt",

					items = function()
						local scanner = require("bluetooth.scanner")
						local _, disconnected_icon = get_icons()
						return scanner.get_unpaired_devices(disconnected_icon)
					end,

					preview = function(item)
						local scanner = require("bluetooth.scanner")
						return scanner.preview_device(item)
					end,

					execute = function(items)
						local scanner = require("bluetooth.scanner")
						if not items or #items == 0 then
							return "Error: No device selected", 1
						end

						local selected = items[1]

						-- Don't try to pair scanning/tip messages
						if selected:match("🔍") or selected:match("💡") then
							return "Please wait for devices to appear in the scan", 1
						end

						local address = scanner.extract_address(selected)
						return scanner.pair_device(address)
					end,
				},
			},
		},
	},
}
