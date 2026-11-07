# My Audio (`raqune.audio`)

Volume slider, output picker, per-app mixer

## Overview
- Custom user-owned Omarchy Shell plugin with live theme-adaptive CAD styling.
- Theme-adaptive CAD icon template: `audio-cad.svg.tpl`

## Installation

### Unified Suite Installation (Recommended)
From the root of the **Omarchy Plugins** repository:
```bash
./install.sh
```

### Standalone Installation
```bash
mkdir -p ~/.config/omarchy/plugins/raqune.audio
cp -r ./* ~/.config/omarchy/plugins/raqune.audio/
~/.config/omarchy/hooks/theme-set.d/20-sync-cad-icons
omarchy-shell shell rescanPlugins
```
