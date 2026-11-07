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

# 2. Install helper CLI scripts
mkdir -p "${BIN_DEST}"
cp -f "${REPO_DIR}/bin/selective-reading" "${BIN_DEST}/selective-reading"
chmod +x "${BIN_DEST}/selective-reading"
echo "  [+] Installed selective-reading CLI to ${BIN_DEST}/selective-reading"

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

# 5. Ensure SUPER + R keybinding for Selective Reading is in ~/.config/hypr/bindings.lua
if [[ -f "${BINDINGS_LUA}" ]]; then
  if ! grep -q "selective-reading" "${BINDINGS_LUA}"; then
    cat >> "${BINDINGS_LUA}" <<EOF

-- Selective Reading: Read aloud selected text (or stop if currently reading)
o.bind("SUPER + R", "Selective reading", "${HOME}/.local/bin/selective-reading toggle")
EOF
    echo "  [+] Added SUPER + R keybinding to ${BINDINGS_LUA}"
  else
    echo "  [=] SUPER + R keybinding already present in ${BINDINGS_LUA}"
  fi
fi

# 6. Render all *.svg.tpl icons immediately to match the active environment theme
echo "==> Rendering CAD icons to match current Omarchy theme..."
"${HOOKS_DEST}/20-sync-cad-icons" || true

# 7. Reload Hyprland and Omarchy Shell plugins
if command -v hyprctl >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 || true
fi
if command -v omarchy-shell >/dev/null 2>&1; then
  omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
fi

echo "==> Installation complete! All plugins, icons, and positions are active."
