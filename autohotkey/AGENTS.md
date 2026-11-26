# AutoHotkey Setup - Capslock Vim Remap

This project contains an AutoHotkey (AHK) script designed to transform the `Caps Lock` key into a powerful modifier for Vim-style navigation, system controls, and window management. It is primarily intended for users who want to bring the efficiency of Vim home-row computing to the entire Windows environment.

## Project Overview

- **Main Script:** `capslock_remap_vim.ahk`
- **Compiled Executable (optional, not in the repo):** `capslock_remap_vim.exe`
- **Core Technology:** [AutoHotkey](https://www.autohotkey.com/) (v2.0)
- **Primary Functionality:**
    - Disables default Caps Lock behavior.
    - `Caps Lock` (tap) -> `Esc`.
    - `Caps Lock` (held) + `H/J/K/L` -> Arrow keys (Vim-style).
    - `Caps Lock` (held) + `D/U` -> `PageDown` / `PageUp`.
    - `Caps Lock` (held) + `N/M` -> `Backspace` / `Delete`.
    - `Caps Lock` (held) + `,/.` -> `Ctrl+Left` / `Ctrl+Right` (Word movement).
    - System shortcuts for window closing, tab switching, virtual desktops, and volume control.
    - `Caps Lock + Alt + H/J/K/L` window tiling (direct moves, no Win+arrows) and `Caps Lock + '` for task view.
    - Plain `Alt` is never remapped (zellij in Alacritty), and mouse buttons are left to MarbleScroll.

## Usage

### Running the Script
1.  **Through the bootstrap (normal):** `windows\bootstrap.ps1 -Personal` installs AutoHotkey v2 and starts the `.ahk` at login. Without `-Personal` nothing AutoHotkey-related is touched.
2.  **Directly via AHK:** If you have AutoHotkey installed, double-click `capslock_remap_vim.ahk`.
3.  **Via Executable (fallback):** A compiled `capslock_remap_vim.exe` works on a machine without AutoHotkey, but never run it alongside the script.

### Key Mappings Summary
| Shortcut | Action |
| :--- | :--- |
| `Caps Lock` | `Esc` |
| `Caps Lock + H/J/K/L` | Left / Down / Up / Right |
| `Caps Lock + D / U` | Page Down / Page Up |
| `Caps Lock + N / M` | Backspace / Delete |
| `Caps Lock + ;` | Enter |
| `Caps Lock + Space` | Ctrl + Space |
| `Caps Lock + E` | Close Window (`Alt+F4`) |
| `Caps Lock + W` | Close Tab (`Ctrl+F4`) |
| `Caps Lock + Tab / Q` | Next Tab / Previous Tab |
| `Caps Lock + [ / ]` | Switch Virtual Desktops |
| `Caps Lock + Alt + H / L` | Window to left / right half (repeat: next monitor) |
| `Caps Lock + Alt + K / J` | Maximize / Restore or minimize |
| `Caps Lock + Alt + F` | F11 (fullscreen) |

## Development and Modification

- **Editing:** Open `capslock_remap_vim.ahk` in any text editor.
- **Startup:** `windows/bootstrap.ps1` installs AutoHotkey v2 with winget and points the Startup shortcut at `AutoHotkey64.exe` running this `.ahk` directly, so edits only need a script reload (re-run the bootstrap or use the tray menu). Bump the tray tip (`A_IconTip`) when behavior changes.
- **Compiling (optional):** `Ahk2Exe` (install it from AutoHotkey Dash > Compile) can still build `capslock_remap_vim.exe` for machines without AutoHotkey. The `.exe` is gitignored. Do not run it alongside the script; the bootstrap stops a running compiled copy.
- **Validating:** `AutoHotkey64.exe /ErrorStdOut /validate capslock_remap_vim.ahk` (CI runs the same check).
- **Conventions:**
    - Keep one hotkey per line, keep existing comments, and keep LF line endings.
    - The script uses `#HotIf GetKeyState("CapsLock", "P")` for conditional mapping.
    - `{Blind}` is used in many mappings to allow modifier keys (like Shift) to be combined with the remapped keys (e.g., `Caps Lock + Shift + H` to select text to the left).
