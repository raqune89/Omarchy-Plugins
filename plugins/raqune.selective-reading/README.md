# Selective Reading (`raqune.selective-reading`)

Formatting-aware text-to-speech reader for selected text powered by **F5-TTS (`F5TTS_v1_Base`) Flow-Matching + Pre-Trained GPU RVC v2 (48 kHz)** voice models for **Morgan Freeman**, **Stephen Fry**, **Matthew McConaughey**, and **Shayne Topp**, with pause/resume support, live speed scaling, and global Hyprland shortcuts (`SUPER + SHIFT + R` and `SUPER + R`).

## Features
- **Start / Stop Shortcut (`SUPER + SHIFT + R`)**: Highlight text in any browser, terminal, PDF, or editor and press `SUPER + SHIFT + R` to read it aloud. Press `SUPER + SHIFT + R` again while reading (or paused) to stop immediately.
- **Pause / Resume Shortcut (`SUPER + R`)**: Press `SUPER + R` during playback to pause immediately, and press `SUPER + R` again to resume from the exact position where you paused.
- **Formatting & Punctuation-Aware Speech**:
  - Automatically parses HTML (`<h1>`–`<h6>`, `<p>`, `<li>`) and plain-text layout so headings/titles receive falling intonation and natural pauses before paragraphs, and bullet lists are spoken item by item.
  - Expands numerals, years (`1993` $\to$ "nineteen ninety-three"), currency (`$4,500` $\to$ "four thousand, five hundred dollars"), percentages (`25%` $\to$ "twenty-five percent"), and ordinals (`1st` $\to$ "first") via `num2words`.
  - Normalizes common abbreviations (`Dr.`, `Mr.`, `e.g.`, `i.e.`, `etc.`, `vs.`) and strips markdown noise while preserving readable anchor text.
  - Sentence-aware flow-matching chunking prevents mid-clause truncation at commas, guaranteeing smooth, natural prosody.
- **Celebrity Voice Models (GPU Flow-Matching + RVC v2)**:
  - **Morgan Freeman** (`MorganFreeman_e440_s4840` RVC v2 + studio narration reference)
  - **Stephen Fry** (`StephenFry64` RVC v2 + Audible studio booth reference)
  - **Matthew McConaughey** (`matthew_mcconaughey_e1050_s40950` 48 kHz RVC v2 + *Greenlights* studio reference with relaxed, signature Texas drawl pacing at ~135 WPM)
  - **Shayne Topp** (Context-adaptive dual-reference neural voice: dynamically switches between calm/introspective studio dialogue and boisterous/hyped Smosh Reddit Stories delivery based on punctuation and emotional context; includes dedicated **Calm** and **Hype** presets)
- **Distortion-Free Speed Controls (`scaletempo2`)**: Adjust playback speed between `0.85x`, `1.0x`, `1.15x`, and `1.3x` (including live mid-playback changes via `mpv` IPC) without neural vocoder artifacts.
- **Volume Controls & Presets**: Continuous `0%`–`100%` slider, quick preset buttons (`Mute`, `50%`, `75%`, `100%`), and CLI control (`selective-reading set-volume <0-100|+N|-N>`) with live mid-playback volume scaling via `mpv` IPC.
- **Theme-Adaptive CAD Icon**: Includes `selective-reading-cad.svg.tpl` synced automatically on theme switch.

## Dependencies
- `uv` (provisions Python 3.12 virtualenv with `f5-tts`, `vocos`, `inferrvc`, `faiss-cpu`, `transformers`, and CUDA `torch` in `~/.local/share/omarchy/selective-reading/venv`)
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
