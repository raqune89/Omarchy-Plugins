# Target HUD (`raqune.target-hud`)

A tactical CTF target IP and VPN (`tun0`) tracker widget for the Omarchy status bar.

## Features
- Automatically detects and displays your active `tun0` VPN IP address.
- Stores and displays your current CTF target IP (`~/.local/state/omarchy/ctf/target.json`).
- One-click copy for both `tun0` IP and Target IP to the Wayland clipboard (`wl-copy`).
- Quick action to map the target IP to a hostname in `/etc/hosts`.
- Theme-adaptive CAD icon (`target-hud-cad.svg.tpl`) rendered automatically on theme change.

## Dependencies
- `iproute2` (`ip`)
- `wl-clipboard` (`wl-copy`)
- Omarchy Shell (`omarchy-shell`)

## Installation

### Unified Suite Installation (Recommended)
From the root of the **Omarchy Plugins** repository:
```bash
./install.sh
```

### Standalone Installation
1. Copy this folder to `~/.config/omarchy/plugins/raqune.target-hud/`:
   ```bash
   mkdir -p ~/.config/omarchy/plugins/raqune.target-hud
   cp -r ./* ~/.config/omarchy/plugins/raqune.target-hud/
   ```
2. Render the theme icon and reload plugins:
   ```bash
   ~/.config/omarchy/hooks/theme-set.d/20-sync-cad-icons
   omarchy-shell shell rescanPlugins
   ```
3. Add `{"id": "raqune.target-hud"}` to `bar.layout.centerBegin` in `~/.config/omarchy/shell.json`.
