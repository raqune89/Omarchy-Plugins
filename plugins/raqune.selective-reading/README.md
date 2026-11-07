# Selective Reading (`raqune.selective-reading`)

Formatting-aware text-to-speech reader for selected text with realistic neural voices, pause/resume support, and global Hyprland shortcuts (`SUPER + SHIFT + R` and `SUPER + R`).

## Features
- **Start / Stop Shortcut (`SUPER + SHIFT + R`)**: Highlight text in any browser, terminal, PDF, or editor and press `SUPER + SHIFT + R` to read it aloud. Press `SUPER + SHIFT + R` again while reading (or paused) to stop immediately.
- **Pause / Resume Shortcut (`SUPER + R`)**: Press `SUPER + R` during playback to pause immediately, and press `SUPER + R` again to resume from the exact position where you paused.
- **Formatting-Aware Speech**: Parses HTML (`<h1>`–`<h6>`, `<p>`, `<li>`) and plain-text layout so headings/titles receive falling intonation and ~1s pauses before paragraphs, and bullet lists are spoken item by item.
- **6 Realistic Neural Voices**: Switch between **Jenny**, **Guy**, **Aria**, **Christopher**, **Sonia**, and **Ryan** with one-click voice preview (`Sample`).
- **Speed Controls**: Adjust playback speed between `0.85x`, `1.0x`, `1.15x`, and `1.3x`.
- **Theme-Adaptive CAD Icon**: Includes `selective-reading-cad.svg.tpl` synced automatically on theme switch.

## Dependencies
- `uv` (runs `edge-tts` automatically via `uv run --with edge-tts`)
- `mpv` (audio streaming & IPC pause/resume playback)
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
4. Add the keybindings to `~/.config/hypr/bindings.lua`:
   ```lua
   o.bind("SUPER + SHIFT + R", "Selective reading (start/stop)", "/home/raqune/.local/bin/selective-reading toggle")
   o.bind("SUPER + R", "Selective reading (pause/resume)", "/home/raqune/.local/bin/selective-reading pause")
   ```
   Then run `hyprctl reload`.
