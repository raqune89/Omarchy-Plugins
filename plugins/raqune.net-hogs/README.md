# Net Hogs (`raqune.net-hogs`)

Live network RX/TX throughput monitor for the Omarchy status bar.

## Features
- Reads `/proc/net/dev` every 2 seconds across all non-loopback interfaces to calculate real-time download (RX) and upload (TX) speeds.
- Displays live bandwidth rates in the tooltip and popup panel, with a shortcut to launch an interactive network monitor.
- Theme-adaptive CAD icon (`net-hogs-cad.svg.tpl`).

## Dependencies
- `gawk` (`awk`)
- Omarchy Shell (`omarchy-shell`)

## Installation

### Unified Suite Installation (Recommended)
```bash
./install.sh
```

### Standalone Installation
1. Copy this folder to `~/.config/omarchy/plugins/raqune.net-hogs/`:
   ```bash
   mkdir -p ~/.config/omarchy/plugins/raqune.net-hogs
   cp -r ./* ~/.config/omarchy/plugins/raqune.net-hogs/
   ```
2. Render the theme icon and reload plugins:
   ```bash
   ~/.config/omarchy/hooks/theme-set.d/20-sync-cad-icons
   omarchy-shell shell rescanPlugins
   ```
3. Add `{"id": "raqune.net-hogs"}` to `bar.layout.centerBegin` in `~/.config/omarchy/shell.json`.
