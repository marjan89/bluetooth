-- devices.lua - Bluetooth device management
-- Handles querying, parsing, and formatting Bluetooth devices

local json = require("json")

local M = {}

---Format device for display with connection indicator
---@param device table Device object {name, address, connected}
---@param connected_icon string Icon for connected devices (default: "◍")
---@param disconnected_icon string Icon for disconnected devices (default: "○")
---@return string Formatted device string
function M.format_device(device, connected_icon, disconnected_icon)
	connected_icon = connected_icon or "◍"
	disconnected_icon = disconnected_icon or "○"
	local indicator = device.connected and (connected_icon .. " ") or (disconnected_icon .. " ")
	return string.format("%s%s\t%s", indicator, device.name, device.address)
end

---Extract device address from formatted item
---@param item string Formatted device string
---@return string Device address
function M.extract_address(item)
	local address = item:match("\t(.+)$")
	return address or ""
end

---Extract device name from formatted item
---@param item string Formatted device string
---@return string Device name
function M.extract_name(item)
	-- Remove any icon prefix (single character/emoji + space) and extract name before tab
	local name = item:match("^. (.+)\t")
	return name or ""
end

---Check if device is currently connected
---@param item string Formatted device string
---@param connected_icon string Icon for connected devices (default: "◍")
---@return boolean True if connected
function M.is_connected(item, connected_icon)
	connected_icon = connected_icon or "◍"
	local escaped = connected_icon:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
	return item:match("^" .. escaped .. " ") ~= nil
end

---Get all paired Bluetooth devices from blueutil
---@param connected_icon string Icon for connected devices (default: "◍")
---@param disconnected_icon string Icon for disconnected devices (default: "○")
---@return string[] Array of formatted device strings, or error messages
function M.get_paired_devices(connected_icon, disconnected_icon)
	-- Check if blueutil is installed
	local _, check_code = syntropy.shell("command -v blueutil >/dev/null 2>&1")
	if check_code ~= 0 then
		return { "Error: blueutil not installed. Install with: brew install blueutil" }
	end

	-- Get paired devices
	local json_output, code = syntropy.shell("blueutil --paired --format json")

	if code ~= 0 then
		return { "Error: Failed to get Bluetooth devices" }
	end

	if json_output == "" or json_output == "[]" then
		return { "No paired Bluetooth devices found" }
	end

	-- Parse JSON
	local success, devices = pcall(json.decode, json_output)
	if not success or not devices then
		return { "Error: Failed to parse Bluetooth device data" }
	end

	if #devices == 0 then
		return { "No paired Bluetooth devices found" }
	end

	-- Format for display
	local items = {}
	for _, device in ipairs(devices) do
		table.insert(items, M.format_device(device, connected_icon, disconnected_icon))
	end

	return items
end

---Connect to a Bluetooth device
---@param address string Device address
---@return string output Command output
---@return number code Exit code
function M.connect_device(address)
	local cmd = string.format("blueutil --connect '%s' 2>&1", address)
	return syntropy.shell(cmd)
end

---Disconnect from a Bluetooth device
---@param address string Device address
---@return string output Command output
---@return number code Exit code
function M.disconnect_device(address)
	local cmd = string.format("blueutil --disconnect '%s' 2>&1", address)
	return syntropy.shell(cmd)
end

---Unpair a Bluetooth device
---@param address string Device address
---@return string output Command output
---@return number code Exit code
function M.unpair_device(address)
	local cmd = string.format("blueutil --unpair '%s' 2>&1", address)
	return syntropy.shell(cmd)
end

return M
