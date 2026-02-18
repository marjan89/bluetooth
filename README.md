# Bluetooth Plugin

**Bluetooth device switcher with connection toggle**

Manage Bluetooth devices on macOS: connect/disconnect paired devices, discover and pair new devices, or permanently unpair unwanted devices through a fuzzy-searchable interface.

## Installation

Add to your `~/.config/syntropy/plugins.toml`:

```toml
[plugins.syntropy-bluetooth]
git = "https://github.com/marjan89/bluetooth.git"
tag = "v1.0.0"
```

Then restart Syntropy or reload plugins.

## Features

- **Toggle Connection** - Quickly connect or disconnect from any paired Bluetooth device
- **Scan & Pair** - Discover nearby unpaired devices and pair them with a single action
- **Forget Devices** - Permanently unpair devices you no longer use

## Tasks

### `toggle`

Connect or disconnect paired Bluetooth devices. Shows current connection status and toggles it when executed.

### `scan`

Continuously scan for unpaired Bluetooth devices. Automatically refreshes the list every 10 seconds. Select a device to pair it.

### `forget`

Permanently unpair a Bluetooth device. Includes confirmation to prevent accidental unpairing.

## Requirements

- **Platform**: macOS only
- **Dependencies**: `blueutil` (installed via Homebrew: `brew install blueutil`)

## Usage

```bash
# Toggle device connection
syntropy bluetooth toggle

# Scan for new devices
syntropy bluetooth scan

# Unpair a device
syntropy bluetooth forget
```

## Configuration

The plugin uses Unicode circle icons by default:
- `◍` for connected devices
- `○` for disconnected devices

### Customizing Icons

You can override the default icons by creating a configuration file:

1. Create the configuration directory:
   ```bash
   mkdir -p ~/.config/syntropy/plugins/bluetooth
   ```

2. Copy the example configuration:
   ```bash
   cp config_example.lua ~/.config/syntropy/plugins/bluetooth/plugin.lua
   ```

3. Edit `~/.config/syntropy/plugins/bluetooth/plugin.lua` and customize the icons:
   ```lua
   return {
       metadata = {
           name = "bluetooth",
           version = "1.0.0",
       },
       config = {
           connected_icon = "󰂱",     -- Your preferred connected icon
           disconnected_icon = "󰂯",  -- Your preferred disconnected icon
       },
   }
   ```

See `config_example.lua` for more icon examples (Nerd Fonts, emoji, ASCII).

## License

MIT License - see [LICENSE](LICENSE) file for details.
