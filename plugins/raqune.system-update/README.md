# My Omarchy update (`raqune.system-update`)

Indicates available Omarchy updates

## Overview
- Custom user-owned Omarchy Shell plugin with live theme-adaptive CAD styling.
- Theme-adaptive CAD icon template: `system-update-cad.svg.tpl`

## Installation

### Unified Suite Installation (Recommended)
From the root of the **Omarchy Plugins** repository:
```bash
./install.sh
```

### Standalone Installation
```bash
mkdir -p ~/.config/omarchy/plugins/raqune.system-update
cp -r ./* ~/.config/omarchy/plugins/raqune.system-update/
~/.config/omarchy/hooks/theme-set.d/20-sync-cad-icons
omarchy-shell shell rescanPlugins
```
