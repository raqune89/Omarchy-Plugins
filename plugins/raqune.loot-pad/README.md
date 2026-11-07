# Loot Pad (`raqune.loot-pad`)

Compact CTF target flags (`user.txt`, `root.txt`) and credentials scratchpad for the Omarchy status bar.

## Features
- Persists `userFlag`, `rootFlag`, and `creds` notes in `~/.local/state/omarchy/ctf/loot.json`.
- Live file watching via `FileView` and one-click clipboard copy (`wl-copy`) with desktop notification confirmation.
- Theme-adaptive CAD icon (`loot-pad-cad.svg.tpl`).

## Dependencies
- `wl-clipboard` (`wl-copy`)
- Omarchy Shell (`omarchy-shell`)

## Installation

### Unified Suite Installation (Recommended)
```bash
./install.sh
```

### Standalone Installation
1. Copy this folder to `~/.config/omarchy/plugins/raqune.loot-pad/`:
   ```bash
   mkdir -p ~/.config/omarchy/plugins/raqune.loot-pad
   cp -r ./* ~/.config/omarchy/plugins/raqune.loot-pad/
   ```
2. Render the theme icon and reload plugins:
   ```bash
   ~/.config/omarchy/hooks/theme-set.d/20-sync-cad-icons
   omarchy-shell shell rescanPlugins
   ```
3. Add `{"id": "raqune.loot-pad"}` to `bar.layout.centerBegin` in `~/.config/omarchy/shell.json`.
