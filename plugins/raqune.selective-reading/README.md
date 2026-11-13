# Selective Reading (`raqune.selective-reading`)

Formatting-aware text-to-speech reader for selected text powered by **F5-TTS (`F5TTS_v1_Base`) Flow-Matching** neural voice models for the Smosh cast (**Shayne Topp**, **Angela Giarratana**, and **Amanda Lehan-Canto**), with pause/resume support, natural speaker pacing, and global Hyprland shortcuts (`SUPER + SHIFT + R` and `SUPER + R`).

## Features
- **Start / Stop Shortcut (`SUPER + SHIFT + R`)**: Highlight text in any browser, terminal, PDF, or editor and press `SUPER + SHIFT + R` to read it aloud. Press `SUPER + SHIFT + R` again while reading (or paused) to stop immediately.
- **Pause / Resume Shortcut (`SUPER + R`)**: Press `SUPER + R` during playback to pause immediately, and press `SUPER + R` again to resume from the exact position where you paused.
- **Formatting & Punctuation-Aware Speech**:
  - Automatically parses HTML (`<h1>`–`<h6>`, `<p>`, `<li>`) and plain-text layout so headings/titles receive falling intonation and natural pauses before paragraphs, and bullet lists are spoken item by item.
  - Expands numerals, years (`1993` $\to$ "nineteen ninety-three"), currency (`$4,500` $\to$ "four thousand, five hundred dollars"), percentages (`25%` $\to$ "twenty-five percent"), and ordinals (`1st` $\to$ "first") via `num2words`.
  - Intelligently pre-analyzes and normalizes code expressions, snake_case identifiers (`first_sample` $\to$ "first sample"), math/physics formulas & units (`E = mc2` $\to$ "E equals m c squared", `100ms` $\to$ "100 milliseconds", `km/s` $\to$ "kilometers per second", `MeV/c2` $\to$ "mega electron volts per c squared"), decimals (`0.00000` $\to$ "zero point zero"), and acronyms using phonetic spellings (`RMS` $\to$ "are em ess", `GPU` $\to$ "jee pee you", `ASR` $\to$ "ay ess are", plus consonant-only initialisms).
  - Normalizes common abbreviations (`Dr.`, `Mr.`, `e.g.`, `i.e.`, `etc.`, `vs.`) and strips markdown noise while preserving readable anchor text.
  - Syntactic clause-level chunking preserves natural prosodic arcs and continuation intonation on commas without mid-phrase chopping or artificial period insertion.
  - Inter-sentence breath pauses (180ms) between thoughts simulate authentic human speech cadence.
- **Smosh Cast Voice Models (Pure F5-TTS Neural Voices at Authentic Natural Speed)**:
  - **Shayne Topp** (Context-adaptive dual-reference neural voice: calm studio reference calibrated to a relaxed, natural ~140 WPM talking pace with smooth onset fading, plus high-energy dynamic reference)
  - **Angela Giarratana** (Studio interview reference: bright, expressive, dynamic comedy and narrative cadence at natural talking pace)
  - **Amanda Lehan-Canto** (Studio interview reference: warm, animated, natural conversational storytelling at natural talking pace)
  - **Expanded Reference Library**: Each voice includes calibrated master and secondary studio reference audio files (`_ref.wav` and `_ref2.wav`) in the voices library.
- **Volume Controls & Presets**: Continuous `0%`–`100%` slider, quick preset buttons (`Mute`, `50%`, `75%`, `100%`), and CLI control (`selective-reading set-volume <0-100|+N|-N>`) with live mid-playback volume scaling via `mpv` IPC.
- **Theme-Adaptive CAD Icon**: Includes `selective-reading-cad.svg.tpl` synced automatically on theme switch.

## Dependencies
- `uv` (provisions Python 3.12 virtualenv with `f5-tts`, `vocos`, `inferrvc`, `faiss-cpu`, `transformers`, and CUDA `torch` in `~/.local/share/omarchy/selective-reading/venv`)
- `mpv` (44.1 kHz raw PCM audio streaming & IPC pause/resume/volume playback)
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
