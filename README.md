# Omarchy Plugins

Complete suite of custom Omarchy status bar tools, tactical CAD-themed bar widgets, live theme synchronization hook, and layout configuration.

Designed so that after a fresh Omarchy installation, a single command restores every tool, shortcut, and bar icon in its exact position while automatically matching the active Omarchy theme.

---

## Quick Reinstall (All-in-One)

```bash
git clone https://github.com/raqune/Omarchy-Plugins.git
cd Omarchy-Plugins
./install.sh
```

### What `./install.sh` Does:
1. Installs all **10 custom menu bar tools** and **13 CAD-styled core bar widgets** into `~/.config/omarchy/plugins/`.
2. Installs the formatting-aware **`selective-reading`** F5-TTS + RVC v2 GPU celebrity voice CLI to `~/.local/bin/selective-reading` and caches the local **Morgan Freeman**, **Stephen Fry**, **Matthew McConaughey**, and **Shayne Topp** voice models.
3. Installs the **`20-sync-cad-icons`** theme hook to `~/.config/omarchy/hooks/theme-set.d/20-sync-cad-icons`.
4. Restores `~/.config/omarchy/shell.json` so every icon remains in its exact bar section and order (`left`, `centerBegin`, `center`, `centerEnd`, `right`).
5. Configures the **`SUPER + SHIFT + R`** (start/stop) and **`SUPER + R`** (pause/resume) global shortcuts in `~/.config/hypr/bindings.lua` for **Selective Reading**.
6. Immediately executes `20-sync-cad-icons` to render all `*.svg.tpl` icons using the active theme's color palette (`~/.local/state/omarchy/current/theme/colors.toml`), and hot-reloads `omarchy-shell` and Hyprland.

---

## Bar Layout & Included Tools

### Custom Tools (`centerBegin` — Left of Clock)

| Position | Plugin ID | Tool Name | Description | Documentation |
| :---: | :--- | :--- | :--- | :--- |
| 1 | `raqune.target-hud` | **Target HUD** | CTF target IP & `tun0` VPN IP tracker, `/etc/hosts` mapper, and quick-copy utility | [README](plugins/raqune.target-hud/README.md) |
| 2 | `raqune.web-spawner` | **Web Spawner** | One-click Python HTTP payload server & `wget`/`curl`/`certutil` stager generator | [README](plugins/raqune.web-spawner/README.md) |
| 3 | `raqune.payload-vault` | **Payload Vault** | Reverse shell & TTY upgrade generator dynamically bound to `tun0` IP and port | [README](plugins/raqune.payload-vault/README.md) |
| 4 | `raqune.tun-switcher` | **VPN Switcher** | OpenVPN (`tun0`) status & ping latency monitor for HTB/THM with quick launcher | [README](plugins/raqune.tun-switcher/README.md) |
| 5 | `raqune.port-guard` | **Port Guard** | Live local listening TCP port scanner (`ss -tlpn`) and service monitor | [README](plugins/raqune.port-guard/README.md) |
| 6 | `raqune.loot-pad` | **Loot Pad** | Persistent CTF `user.txt`, `root.txt`, and credentials scratchpad | [README](plugins/raqune.loot-pad/README.md) |
| 7 | `raqune.game-boost` | **Game Boost** | Steam / GameMode detector & low-latency Hyprland compositor optimizer | [README](plugins/raqune.game-boost/README.md) |
| 8 | `raqune.net-hogs` | **Net Hogs** | Real-time network RX/TX bandwidth rate monitor | [README](plugins/raqune.net-hogs/README.md) |

### Custom Tools (`centerEnd` — Right of Clock)

| Position | Plugin ID | Tool Name | Description | Documentation |
| :---: | :--- | :--- | :--- | :--- |
| 3 | `jesseburlamaque.antigravity-usage` | **Antigravity Usage** | Antigravity AI quota and active session monitor (with custom CAD icon template) | [README](plugins/jesseburlamaque.antigravity-usage/README.md) |
| 5 | `raqune.selective-reading` | **Selective Reading** | Formatting-aware F5-TTS + RVC v2 GPU TTS reader (`SUPER + SHIFT + R` start/stop, `SUPER + R` pause/resume) with **Morgan Freeman**, **Stephen Fry**, **Matthew McConaughey**, & **Shayne Topp** voices | [README](plugins/raqune.selective-reading/README.md) |

### Floating On-Demand Tools (No Status-Bar Icon)

| Plugin ID | Tool Name | Description | Keybindings | Documentation |
| :--- | :--- | :--- | :--- | :--- |
| `raqune.nodo-pad` | **NoDo-pad** | Floating dual-tab formattable scratchpad & interactive todo list | `SUPER + ALT + T` (Toggle)<br>`SUPER + ALT + N` (Switch tab) | [README](plugins/raqune.nodo-pad/README.md) |

### CAD-Themed Core Bar Widgets
Also included so the entire bar shares a unified tactical CAD visual language:
- **Left**: [`raqune.menu`](plugins/raqune.menu/README.md), [`raqune.workspaces`](plugins/raqune.workspaces/README.md)
- **Center**: [`raqune.clock`](plugins/raqune.clock/README.md)
- **Center End**: [`raqune.elsewhen`](plugins/raqune.elsewhen/README.md), [`raqune.weather`](plugins/raqune.weather/README.md), [`raqune.system-update`](plugins/raqune.system-update/README.md)
- **Right**: `omarchy.tray`, `omarchy.keyboard-layout`, [`raqune.bluetooth`](plugins/raqune.bluetooth/README.md), [`raqune.network`](plugins/raqune.network/README.md), [`raqune.audio`](plugins/raqune.audio/README.md), [`raqune.monitor`](plugins/raqune.monitor/README.md), [`raqune.power`](plugins/raqune.power/README.md)

---

## Automatic Theme Matching (`20-sync-cad-icons`)

Every custom icon in `plugins/` ships with a `.svg.tpl` template using theme placeholders (`{{accent}}`, `{{green}}`, `{{yellow}}`, `{{red}}`, `{{muted}}`, `{{bg}}`).

Whenever you switch themes via `omarchy theme set <theme>` (or run `./install.sh`), `~/.config/omarchy/hooks/theme-set.d/20-sync-cad-icons` automatically reads `~/.local/state/omarchy/current/theme/colors.toml`, regenerates every `.svg` icon to match the active theme palette, and triggers `omarchy-shell -q shell rescanPlugins`.
