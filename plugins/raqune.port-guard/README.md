# Port Guard (`raqune.port-guard`)

Local TCP listening port scanner and service inspector widget for the Omarchy status bar.

## Features
- Periodically scans local listening TCP sockets via `ss -tlpn`.
- Displays a 3-column table (`PORT`, `APP / SERVICE`, `BIND IP`) showing the port number, the owning process/PID or resolved system service (`systemd-resolved`, `cupsd`, `sshd`, `/etc/services`), and the bind IP address.
- Theme-adaptive CAD icon (`port-guard-cad.svg.tpl`).

## Dependencies
- `iproute2` (`ss`)
- `gawk` (`awk`), `sed`
- Omarchy Shell (`omarchy-shell`)

## Installation

### Unified Suite Installation (Recommended)
```bash
./install.sh
```

### Standalone Installation
1. Copy this folder to `~/.config/omarchy/plugins/raqune.port-guard/`:
   ```bash
   mkdir -p ~/.config/omarchy/plugins/raqune.port-guard
   cp -r ./* ~/.config/omarchy/plugins/raqune.port-guard/
   ```
2. Render the theme icon and reload plugins:
   ```bash
   ~/.config/omarchy/hooks/theme-set.d/20-sync-cad-icons
   omarchy-shell shell rescanPlugins
   ```
3. Add `{"id": "raqune.port-guard"}` to `bar.layout.centerBegin` in `~/.config/omarchy/shell.json`.
