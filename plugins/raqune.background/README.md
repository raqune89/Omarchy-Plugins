# My Background (`raqune.background`)

Desktop background renderer with click handling and transitions

## Overview
- Custom user-owned Omarchy Shell plugin with live theme-adaptive CAD styling.

## Installation

### Unified Suite Installation (Recommended)
From the root of the **Omarchy Plugins** repository:
```bash
./install.sh
```

### Standalone Installation
```bash
mkdir -p ~/.config/omarchy/plugins/raqune.background
cp -r ./* ~/.config/omarchy/plugins/raqune.background/
~/.config/omarchy/hooks/theme-set.d/20-sync-cad-icons
omarchy-shell shell rescanPlugins
```
