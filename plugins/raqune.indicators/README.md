# My Indicators (`raqune.indicators`)

Manual state indicators

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
mkdir -p ~/.config/omarchy/plugins/raqune.indicators
cp -r ./* ~/.config/omarchy/plugins/raqune.indicators/
~/.config/omarchy/hooks/theme-set.d/20-sync-cad-icons
omarchy-shell shell rescanPlugins
```
