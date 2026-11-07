# Payload Vault (`raqune.payload-vault`)

Reverse shell and interactive TTY stabilization payload generator for the Omarchy status bar.

## Features
- Automatically binds `$LHOST` to your active `tun0` VPN IP and `$LPORT` to your chosen listener port (default `4444`).
- One-click copy for Bash, Python3, Netcat (`mkfifo`), PHP, PowerShell, and Python pty TTY stabilization payloads.
- Theme-adaptive CAD icon (`payload-vault-cad.svg.tpl`).

## Dependencies
- `iproute2` (`ip`)
- `wl-clipboard` (`wl-copy`)
- Omarchy Shell (`omarchy-shell`)

## Installation

### Unified Suite Installation (Recommended)
```bash
./install.sh
```

### Standalone Installation
1. Copy this folder to `~/.config/omarchy/plugins/raqune.payload-vault/`:
   ```bash
   mkdir -p ~/.config/omarchy/plugins/raqune.payload-vault
   cp -r ./* ~/.config/omarchy/plugins/raqune.payload-vault/
   ```
2. Render the theme icon and reload plugins:
   ```bash
   ~/.config/omarchy/hooks/theme-set.d/20-sync-cad-icons
   omarchy-shell shell rescanPlugins
   ```
3. Add `{"id": "raqune.payload-vault"}` to `bar.layout.centerBegin` in `~/.config/omarchy/shell.json`.
