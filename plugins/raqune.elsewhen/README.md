# My Elsewhen (`raqune.elsewhen`)

A world clock for the Omarchy shell: the time in several cities at once, with a spinnable globe.

## Overview
- Custom user-owned Omarchy Shell plugin with live theme-adaptive CAD styling.
- Theme-adaptive CAD icon template: `elsewhen-cad.svg.tpl`

## Installation

### Unified Suite Installation (Recommended)
From the root of the **Omarchy Plugins** repository:
```bash
./install.sh
```

### Standalone Installation
```bash
mkdir -p ~/.config/omarchy/plugins/raqune.elsewhen
cp -r ./* ~/.config/omarchy/plugins/raqune.elsewhen/
~/.config/omarchy/hooks/theme-set.d/20-sync-cad-icons
omarchy-shell shell rescanPlugins
```
