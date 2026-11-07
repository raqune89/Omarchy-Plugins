# My Workspaces (`raqune.workspaces`)

Workspace number indicators

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
mkdir -p ~/.config/omarchy/plugins/raqune.workspaces
cp -r ./* ~/.config/omarchy/plugins/raqune.workspaces/
~/.config/omarchy/hooks/theme-set.d/20-sync-cad-icons
omarchy-shell shell rescanPlugins
```
