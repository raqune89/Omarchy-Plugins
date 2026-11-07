# My Omarchy menu (`raqune.menu`)

Quickshell-powered Omarchy command menu

## Overview
- Custom user-owned Omarchy Shell plugin with live theme-adaptive CAD styling.
- Theme-adaptive CAD icon template: `menu-tactical.svg.tpl`

## Installation

### Unified Suite Installation (Recommended)
From the root of the **Omarchy Plugins** repository:
```bash
./install.sh
```

### Standalone Installation
```bash
mkdir -p ~/.config/omarchy/plugins/raqune.menu
cp -r ./* ~/.config/omarchy/plugins/raqune.menu/
~/.config/omarchy/hooks/theme-set.d/20-sync-cad-icons
omarchy-shell shell rescanPlugins
```
