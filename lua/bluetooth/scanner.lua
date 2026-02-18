-- scanner.lua - Bluetooth device scanning and pairing
-- Handles discovery of unpaired devices and pairing operations

local json = require("json")

local M = {}

---Format device for display with unpaired indicator
---@param device table Device object from scan
---@param unpaired_icon string Icon for unpaired devices (default: "○")
---@return string Formatted device string
function M.format_device(device, unpaired_icon)
	unpaired_icon = unpaired_icon or "○"
	return string.format("%s %s\t%s", unpaired_icon, device.name, device.address)
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

---Scan for nearby Bluetooth devices
---@return table|nil Array of device objects, or nil on error
---@return string|nil Error message if scan failed
function M.scan_devices()
	local output, code = syntropy.shell("blueutil --inquiry 5 --format json")

	if code ~= 0 then
		return nil, "Failed to scan for devices"
	end

	if output == "" or output == "[]" then
		return {}
	end

	local success, devices = pcall(json.decode, output)
	if not success or not devices then
		return nil, "Failed to parse scan results"
	end

	return devices
end

---Get list of already paired devices
---@return table Array of paired device objects
function M.get_paired_devices()
	local output, code = syntropy.shell("blueutil --paired --format json")

	if code ~= 0 or output == "" or output == "[]" then
		return {}
	end

	local success, devices = pcall(json.decode, output)
	return success and devices or {}
end

---Check if a device is already paired
---@param address string Device MAC address
---@param paired_devices table List of paired devices
---@return boolean True if device is already paired
function M.is_device_paired(address, paired_devices)
	for _, paired in ipairs(paired_devices) do
		if paired.address == address then
			return true
		end
	end
	return false
end

---Get list of unpaired devices (scan and filter)
---@param unpaired_icon string Icon for unpaired devices (default: "○")
---@return string[] Array of formatted device strings or status messages
function M.get_unpaired_devices(unpaired_icon)
	-- Check if blueutil is installed
	local _, check_code = syntropy.shell("command -v blueutil >/dev/null 2>&1")
	if check_code ~= 0 then
		return { "Error: blueutil not installed. Install with: brew install blueutil" }
	end

	-- Scan for devices
	local discovered, err = M.scan_devices()
	if not discovered then
		return { err or "Error: Failed to scan for devices" }
	end

	-- Get paired devices to filter them out
	local paired = M.get_paired_devices()

	-- Filter out already paired devices
	local unpaired = {}
	for _, device in ipairs(discovered) do
		if not M.is_device_paired(device.address, paired) then
			table.insert(unpaired, M.format_device(device, unpaired_icon))
		end
	end

	-- Return helpful message if no unpaired devices found
	if #unpaired == 0 then
		return {
			"🔍 Scanning for devices... (auto-refresh every 10s)",
			"💡 Tip: Put your device in pairing mode",
		}
	end

	return unpaired
end

---Generate preview text for a device
---@param item string Formatted device string
---@return string Preview text
function M.preview_device(item)
	-- Handle scanning/tip messages
	if item:match("🔍 Scanning") then
		return [[🔍 Scanning for Bluetooth Devices

Syntropy is continuously scanning for nearby unpaired devices.
New devices will appear automatically in the list.

Scan interval: Every 10 seconds
Scan duration: 5 seconds per scan

Make sure the device you want to pair is:
• Powered on
• In pairing/discoverable mode
• Within Bluetooth range (typically 10 meters)]]
	end

	if item:match("💡 Tip") then
		return [[💡 Pairing Mode Instructions

Most Bluetooth devices have a pairing button or sequence:

Headphones/Speakers:
• Hold power button for 5+ seconds until LED flashes

Keyboards/Mice:
• Look for dedicated pairing button
• Some require holding specific key combinations

Smart Devices:
• Check device manual for pairing instructions
• May require app-based pairing first

The device should appear in the list within 10 seconds.]]
	end

	-- Handle error messages
	if item:match("Error:") then
		return item
	end

	-- Extract device info
	local name = M.extract_name(item)
	local address = M.extract_address(item)

	if not name or name == "" or not address or address == "" then
		return "Error: Could not parse device information"
	end

	return string.format(
		[[○ New Bluetooth Device Detected

Device Name: %s
MAC Address: %s
Status:      Not Paired

Action: Press Enter to Pair

Note: Pairing will be attempted automatically.
      Common PINs (0000, 1234) will be tried if needed.
      Some devices may require manual pairing through
      System Settings > Bluetooth if this fails.]],
		name,
		address
	)
end

---Pair with a Bluetooth device
---@param address string Device MAC address
---@return string output Result message
---@return number code Exit code (0 = success, 1 = failure)
function M.pair_device(address)
	if address == "" then
		return "Error: Could not extract device address", 1
	end

	local name = address -- Fallback name if extraction fails

	-- Attempt to pair without PIN first
	local output, code = syntropy.shell(string.format("blueutil --pair '%s' 2>&1", address))

	if code == 0 then
		return string.format("✓ Successfully paired with %s", name), 0
	end

	-- If pairing failed, try with common PINs
	local common_pins = { "0000", "1234", "1111" }
	for _, pin in ipairs(common_pins) do
		output, code = syntropy.shell(string.format("blueutil --pair '%s' '%s' 2>&1", address, pin))
		if code == 0 then
			return string.format("✓ Successfully paired with %s using PIN %s", name, pin), 0
		end
	end

	-- All pairing attempts failed
	return string.format(
		[[✗ Pairing Failed

Device: %s
Error: %s

Troubleshooting:
1. Ensure device is in pairing/discoverable mode
2. Try pairing manually via System Settings > Bluetooth
3. Some devices require specific PIN codes
4. Device may not support command-line pairing
5. Try resetting the device and scanning again]],
		address,
		output
	), 1
end

return M
