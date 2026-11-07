# VPN Switcher (`raqune.tun-switcher`)

CTF OpenVPN (`tun0`) connection monitor, latency tracker, and launcher for the Omarchy status bar.

## Features
- Monitors `tun0` interface state and identifies HackTheBox, TryHackMe, or general OpenVPN tunnels.
- Measures live ICMP ping latency over the VPN tunnel.
- Simple 2-button workflow: **Connect (`THMvpn`)** opens a terminal window and starts the OpenVPN tunnel without requiring a password prompt, and **Disconnect (`THMstop`)** stops the OpenVPN daemon and closes the VPN terminal window.
- Theme-adaptive CAD icon (`tun-switcher-cad.svg.tpl`).

## Dependencies
- `openvpn`
- `iproute2` (`ip`)
- `iputils` (`ping`)
- Omarchy Shell (`omarchy-shell`)

## Installation

### Unified Suite Installation (Recommended)
```bash
./install.sh
```

### Standalone Installation
1. Copy this folder to `~/.config/omarchy/plugins/raqune.tun-switcher/`:
   ```bash
   mkdir -p ~/.config/omarchy/plugins/raqune.tun-switcher
   cp -r ./* ~/.config/omarchy/plugins/raqune.tun-switcher/
   ```
2. Render the theme icon and reload plugins:
   ```bash
   ~/.config/omarchy/hooks/theme-set.d/20-sync-cad-icons
   omarchy-shell shell rescanPlugins
   ```
3. Add `{"id": "raqune.tun-switcher"}` to `bar.layout.centerBegin` in `~/.config/omarchy/shell.json`.
