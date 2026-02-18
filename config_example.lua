-- Configuration example for syntropy-bluetooth plugin
--
-- This file shows how to override the default bluetooth plugin settings.
--
-- To use this configuration:
-- 1. Create the directory: ~/.config/syntropy/plugins/syntropy-bluetooth/
-- 2. Copy this file to: ~/.config/syntropy/plugins/syntropy-bluetooth/plugin.lua
-- 3. Modify the config values as desired
--
-- The configuration will be automatically loaded when the plugin starts.

---@type PluginOverride
return {
	metadata = {
		name = "bluetooth",  -- Must match the plugin name
		version = "1.0.0",
	},

	config = {
		-- Icons used to indicate device status
		-- Default values use standard Unicode circles:
		connected_icon = "◍",      -- Icon for connected device
		disconnected_icon = "○",   -- Icon for disconnected device

		-- Example: Use Nerd Font icons (requires a Nerd Font to be installed)
		-- connected_icon = "󰂱",     -- Nerd Font bluetooth connected icon
		-- disconnected_icon = "󰂯",  -- Nerd Font bluetooth disconnected icon

		-- Example: Use emoji
		-- connected_icon = "✓",
		-- disconnected_icon = "○",

		-- Example: Use simple ASCII
		-- connected_icon = "*",
		-- disconnected_icon = "-",
	},
}
