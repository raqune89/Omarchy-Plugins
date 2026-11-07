#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DEST="${HOME}/.config/omarchy/plugins"
HOOKS_DEST="${HOME}/.config/omarchy/hooks/theme-set.d"
BIN_DEST="${HOME}/.local/bin"
SHELL_JSON="${HOME}/.config/omarchy/shell.json"
BINDINGS_LUA="${HOME}/.config/hypr/bindings.lua"

echo "==> Installing Omarchy Plugins Suite..."

# 1. Install all plugins (custom tools + CAD-styled bar widgets)
mkdir -p "${PLUGINS_DEST}"
cp -r "${REPO_DIR}/plugins/"* "${PLUGINS_DEST}/"
echo "  [+] Installed $(ls -1d "${REPO_DIR}/plugins/"* | wc -l) plugins to ${PLUGINS_DEST}"

# 2. Install helper CLI scripts & pre-cache F5-TTS + RVC v2 GPU celebrity voice models
mkdir -p "${BIN_DEST}"
mkdir -p "${HOME}/.local/share/omarchy/selective-reading/voices"
cp -f "${REPO_DIR}/plugins/raqune.selective-reading/voices/"*_ref.wav "${HOME}/.local/share/omarchy/selective-reading/voices/" 2>/dev/null || true
cp -f "${REPO_DIR}/bin/selective-reading" "${BIN_DEST}/selective-reading"
chmod +x "${BIN_DEST}/selective-reading"
echo "  [+] Installed selective-reading CLI to ${BIN_DEST}/selective-reading"
echo "  [*] Ensuring F5-TTS + RVC v2 celebrity voice models (Morgan Freeman, Stephen Fry & Matthew McConaughey) are cached..."
"${BIN_DEST}/selective-reading" setup || true

# 3. Install theme-set hook for live CAD SVG icon color rendering
mkdir -p "${HOOKS_DEST}"
cp -f "${REPO_DIR}/hooks/theme-set.d/20-sync-cad-icons" "${HOOKS_DEST}/20-sync-cad-icons"
chmod +x "${HOOKS_DEST}/20-sync-cad-icons"
echo "  [+] Installed theme synchronization hook to ${HOOKS_DEST}/20-sync-cad-icons"

# 4. Install shell.json bar layout (preserving exact icon order and positions)
mkdir -p "$(dirname "${SHELL_JSON}")"
if [[ -f "${SHELL_JSON}" ]] && ! cmp -s "${REPO_DIR}/config/shell.json" "${SHELL_JSON}"; then
  cp -f "${SHELL_JSON}" "${SHELL_JSON}.bak.$(date +%s)"
  echo "  [i] Backed up previous shell.json"
fi
cp -f "${REPO_DIR}/config/shell.json" "${SHELL_JSON}"
echo "  [+] Applied bar layout to ${SHELL_JSON}"

# 5. Ensure SUPER + SHIFT + R (start/stop) and SUPER + R (pause/resume) keybindings are in ~/.config/hypr/bindings.lua
if [[ -f "${BINDINGS_LUA}" ]]; then
  if ! grep -q "selective-reading" "${BINDINGS_LUA}"; then
    cat >> "${BINDINGS_LUA}" <<EOF

-- Selective Reading: Start/stop reading (SUPER + SHIFT + R) and pause/resume (SUPER + R)
o.bind("SUPER + SHIFT + R", "Selective reading (start/stop)", "${HOME}/.local/bin/selective-reading toggle")
o.bind("SUPER + R", "Selective reading (pause/resume)", "${HOME}/.local/bin/selective-reading pause")
EOF
    echo "  [+] Added Selective Reading keybindings (SUPER + SHIFT + R, SUPER + R) to ${BINDINGS_LUA}"
  else
    echo "  [=] Selective Reading keybindings already present in ${BINDINGS_LUA}"
  fi
fi

# 6. Render all *.svg.tpl icons immediately to match the active environment theme
echo "==> Rendering CAD icons to match current Omarchy theme..."
"${HOOKS_DEST}/20-sync-cad-icons" || true

# 7. Reload Hyprland and restart Omarchy Shell so updated QML plugins load cleanly
if command -v hyprctl >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 || true
fi
if command -v omarchy >/dev/null 2>&1; then
  omarchy restart shell >/dev/null 2>&1 || true
elif command -v omarchy-shell >/dev/null 2>&1; then
  omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
fi

echo "==> Installation complete! All plugins, icons, and positions are active."
