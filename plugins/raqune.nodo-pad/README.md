# NoDo-pad (`raqune.nodo-pad`)

Floating dual-tab formattable scratchpad & interactive todo list for Omarchy.

No menu-bar icon required — opens on-demand as a lightweight, floating utility window.

---

## Features

### Tab 1: Formattable Notepad
- **Continuous Autosave**: Automatically writes notes to `~/.local/state/omarchy/nodo-pad/notes.html`.
- **Rich Text Formatting**:
  - **Bold** (`Ctrl+B` or toolbar `B`)
  - **Italic** (`Ctrl+I` or toolbar `I`)
  - **Underline** (`Ctrl+U` or toolbar `U`)
  - **Headers**: `H1`, `H2`, `H3`
  - **Bullet Lists**: `• List`
  - **Blockquotes**: `❝ Quote`
  - **Code Blocks**: `</> Code`
  - **Horizontal Dividers**: `― Line`
  - **Clear Format**: `⌫ Clear`

### Tab 2: Interactive Todo List
- **Task Entry**: Type task and hit Enter or click "Add".
- **Completion Checkboxes**: Toggle tasks with strikethrough feedback.
- **Remove to Completed**: Removed tasks automatically sit in a dedicated "Completed" archive.
- **Restore or Purge**: Completed items can be restored back to active tasks (`↩ Restore`) or permanently purged (`🗑`).
- **Autosave**: Persists state to `~/.local/state/omarchy/nodo-pad/todos.json`.

---

## Window & Hotkey Controls

| Shortcut | Description | Action |
|---|---|---|
| `SUPER + ALT + T` | Toggle NoDo-pad | Opens / closes the floating NoDo-pad window |
| `SUPER + ALT + P` | Pin / Unpin NoDo-pad | Toggles window pin state across all workspaces |
| `SUPER + ALT + N` | Switch Tab | Cycles between Notepad and Todo List |
| Header Click & Drag | Move Window | Drag anywhere on the header to reposition window |
| `Escape` | Dismiss Window | Closes NoDo-pad |
