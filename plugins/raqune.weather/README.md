# My Weather (`raqune.weather`)

Weather pill with detail popup

## Overview
- Custom user-owned Omarchy Shell plugin with live theme-adaptive CAD styling.
- Theme-adaptive CAD icon template: `weather-cad.svg.tpl`

## Installation

### Unified Suite Installation (Recommended)
From the root of the **Omarchy Plugins** repository:
```bash
./install.sh
```

### Standalone Installation
```bash
mkdir -p ~/.config/omarchy/plugins/raqune.weather
cp -r ./* ~/.config/omarchy/plugins/raqune.weather/
~/.config/omarchy/hooks/theme-set.d/20-sync-cad-icons
omarchy-shell shell rescanPlugins
```
