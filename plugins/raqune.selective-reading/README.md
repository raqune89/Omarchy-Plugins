# Selective Reading (`raqune.selective-reading`)

Formatting-aware text-to-speech reader for selected text powered by **Kokoro-82M + Pre-Trained GPU RVC v2 (44.1 kHz)** voice models for **Morgan Freeman** and **Stephen Fry**, with pause/resume support, live speed scaling, and global Hyprland shortcuts (`SUPER + SHIFT + R` and `SUPER + R`).

## Features
- **Start / Stop Shortcut (`SUPER + SHIFT + R`)**: Highlight text in any browser, terminal, PDF, or editor and press `SUPER + SHIFT + R` to read it aloud. Press `SUPER + SHIFT + R` again while reading (or paused) to stop immediately.
- **Pause / Resume Shortcut (`SUPER + R`)**: Press `SUPER + R` during playback to pause immediately, and press `SUPER + R` again to resume from the exact position where you paused.
- **Formatting-Aware Speech**: Parses HTML (`<h1>`–`<h6>`, `<p>`, `<li>`) and plain-text layout so headings/titles receive falling intonation and natural pauses before paragraphs, and bullet lists are spoken item by item.
- **Two-Stage Celebrity Voices (Kokoro-82M + 44.1 kHz RVC v2 on GPU)**:
  - **Morgan Freeman** (`MorganFreeman_e440_s4840` RVC v2 + `am_onyx`/`am_michael` base narrator)
  - **Stephen Fry** (`StephenFry64` RVC v2 + `bm_george`/`bm_fable` base narrator)
- **Distortion-Free Speed Controls (`scaletempo2`)**: Adjust playback speed between `0.85x`, `1.0x`, `1.15x`, and `1.3x` (including live mid-playback changes via `mpv` IPC) without neural vocoder artifacts.
- **Theme-Adaptive CAD Icon**: Includes `selective-reading-cad.svg.tpl` synced automatically on theme switch.

## Dependencies
- `uv` (provisions Python 3.12 virtualenv with `kokoro-onnx`, `inferrvc`, `faiss-cpu`, `transformers`, and CUDA `torch` in `~/.local/share/omarchy/selective-reading/venv`)
- `mpv` (44.1 kHz raw PCM audio streaming, `scaletempo2` speed scaling, & IPC pause/resume playback)
- `wl-clipboard` (`wl-paste`)
- `libnotify` (`notify-send`)
- Omarchy Shell (`omarchy-shell`)

## Installation

### Unified Suite Installation (Recommended)
```bash
./install.sh
```

### Standalone Installation
1. Install the backend CLI script, cache the Kokoro-82M + RVC v2 voice models, and launch the warm GPU daemon:
   ```bash
   mkdir -p ~/.local/bin
   cp ../../bin/selective-reading ~/.local/bin/selective-reading
   chmod +x ~/.local/bin/selective-reading
   ~/.local/bin/selective-reading setup
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
