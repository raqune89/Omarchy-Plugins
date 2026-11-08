# Web Spawner (`raqune.web-spawner`)

One-click HTTP payload/file server manager and download stager generator for the Omarchy status bar.

## Features
- Starts and stops a background `python3 -m http.server` on your configurable port (default `8000`).
- Configurable serving directory (default `~/htb`), editable via text input or native directory browser dialog (`zenity`), with state persisted in `~/.local/state/omarchy/ctf/web-spawner.json`.
- Automatically restarts the server when the serving directory is changed while online.
- Automatically detects your `tun0` IP address (falling back to `127.0.0.1`).
- Generates one-click clipboard stagers (`wget`, `curl`) pre-populated with your `tun0` IP and port.
- Theme-adaptive CAD icon (`web-spawner-cad.svg.tpl`).

## Dependencies
- `python3`
- `iproute2` (`ip`)
- `wl-clipboard` (`wl-copy`)
- `zenity` (for directory browse dialog)
- Omarchy Shell (`omarchy-shell`)

## Installation

### Unified Suite Installation (Recommended)
```bash
./install.sh
```

### Standalone Installation
1. Copy this folder to `~/.config/omarchy/plugins/raqune.web-spawner/`:
   ```bash
   mkdir -p ~/.config/omarchy/plugins/raqune.web-spawner
   cp -r ./* ~/.config/omarchy/plugins/raqune.web-spawner/
   ```
2. Render the theme icon and reload plugins:
   ```bash
   ~/.config/omarchy/hooks/theme-set.d/20-sync-cad-icons
   omarchy-shell shell rescanPlugins
   ```
3. Add `{"id": "raqune.web-spawner"}` to `bar.layout.centerBegin` in `~/.config/omarchy/shell.json`.
