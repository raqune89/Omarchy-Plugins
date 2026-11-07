# Game Boost (`raqune.game-boost`)

GameMode monitor and Hyprland compositor latency optimizer for Steam on the Omarchy status bar.

## Features
- Automatically detects active Steam games, Wine/Proton processes, Gamescope, or Feral `gamemoded`.
- Dynamically disables Hyprland window blur and animations during gameplay for maximum FPS and minimum input latency, restoring them automatically when exiting the game.
- Supports manual toggle via right-click on the bar icon or from the popup panel.
- Theme-adaptive CAD icon (`game-boost-cad.svg.tpl`).

## Dependencies
- Hyprland (`hyprctl`)
- Optional: `gamemode` (`gamemoded`)
- Omarchy Shell (`omarchy-shell`)

## Installation

### Unified Suite Installation (Recommended)
```bash
./install.sh
```

### Standalone Installation
1. Copy this folder to `~/.config/omarchy/plugins/raqune.game-boost/`:
   ```bash
   mkdir -p ~/.config/omarchy/plugins/raqune.game-boost
   cp -r ./* ~/.config/omarchy/plugins/raqune.game-boost/
   ```
2. Render the theme icon and reload plugins:
   ```bash
   ~/.config/omarchy/hooks/theme-set.d/20-sync-cad-icons
   omarchy-shell shell rescanPlugins
   ```
3. Add `{"id": "raqune.game-boost"}` to `bar.layout.centerBegin` in `~/.config/omarchy/shell.json`.
