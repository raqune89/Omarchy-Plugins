# Selective Reading (`raqune.selective-reading`)

Formatting-aware text-to-speech reader for selected text with realistic neural voices and a global Hyprland shortcut (`SUPER + R`).

## Features
- **Instant Shortcut (`SUPER + R`)**: Highlight text in any browser, terminal, PDF, or editor and press `SUPER + R` to read it aloud. Press `SUPER + R` again while reading to stop immediately.
- **Formatting-Aware Speech**: Parses HTML (`<h1>`–`<h6>`, `<p>`, `<li>`) and plain-text layout so headings/titles receive falling intonation and ~1s pauses before paragraphs, and bullet lists are spoken item by item.
- **6 Realistic Neural Voices**: Switch between **Jenny**, **Guy**, **Aria**, **Christopher**, **Sonia**, and **Ryan** with one-click voice preview (`Sample`).
- **Speed Controls**: Adjust playback speed between `0.85x`, `1.0x`, `1.15x`, and `1.3x`.
- **Theme-Adaptive CAD Icon**: Includes `selective-reading-cad.svg.tpl` synced automatically on theme switch.

## Dependencies
- `uv` (runs `edge-tts` automatically via `uv run --with edge-tts`)
- `mpv` (audio streaming playback)
- `wl-clipboard` (`wl-paste`)
- `libnotify` (`notify-send`)
- Omarchy Shell (`omarchy-shell`)

## Installation

### Unified Suite Installation (Recommended)
```bash
./install.sh
```

### Standalone Installation
1. Install the backend CLI script:
   ```bash
   mkdir -p ~/.local/bin
   cp ../../bin/selective-reading ~/.local/bin/selective-reading
   chmod +x ~/.local/bin/selective-reading
   ```
2. Install the Omarchy bar plugin:
   ```bash
   mkdir -p ~/.config/omarchy/plugins/raqune.selective-reading
   cp -r ./* ~/.config/omarchy/plugins/raqune.selective-reading/
   ~/.config/omarchy/hooks/theme-set.d/20-sync-cad-icons
   omarchy-shell shell rescanPlugins
   ```
3. Add `{"id": "raqune.selective-reading"}` to `bar.layout.centerEnd` in `~/.config/omarchy/shell.json`.
4. Add the keybinding to `~/.config/hypr/bindings.lua`:
   ```lua
   o.bind("SUPER + R", "Selective reading", "/home/raqune/.local/bin/selective-reading toggle")
   ```
   Then run `hyprctl reload`.
