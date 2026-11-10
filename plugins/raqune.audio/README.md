# My Audio (`raqune.audio`)

Volume slider, output picker, per-app mixer, and media-aware intelligent equalizer.

## Overview
- Custom user-owned Omarchy Shell plugin with live theme-adaptive CAD styling.
- **Media-Aware Equalizer**: Built-in dynamic acoustic equalizer powered by EasyEffects and PipeWire.
  - Automatically identifies playing media (Music, Movie, TV Show, Podcast, Audiobook).
  - Dynamically switches DSP curves for **Speakers** vs. **Headphones**.
  - Movie volume balancing (dialogue elevator & peak compression) and immersive theatre simulation.
  - Vocal articulation and rumble filtering for audiobooks and podcasts.
  - Manual override chips: `[Auto]`, `[Music]`, `[Movie]`, `[TV]`, `[Podcast]`, `[Audiobook]`, and `[Off]`.
- Theme-adaptive CAD icon template: `audio-cad.svg.tpl`

## Keyboard Shortcut
- **`SUPER + ALT + E`**: Cycle equalizer modes on the fly (`Auto` -> `Music` -> `Movie` -> `TV` -> `Podcast` -> `Audiobook` -> `Off`).

## CLI Control
- `media-equalizer status`: View active preset, media detection reason, and hardware sink.
- `media-equalizer auto`: Enable auto media detection.
- `media-equalizer set <mode>`: Manually switch to a mode (`music`, `movie`, `tv`, `podcast`, `audiobook`, `bypass`).
- `media-equalizer next`: Cycle to the next mode.

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
