Vague setup notes in case I need to set up everything again after a hard drive failure.

vimrc
-----

My local .vimrc files.  I'm trying to avoid unnecessary yak-shaving by rolling with whatever comes with [spf13](http://vim.spf13.com/).

## Keyboard and mouse layout

- On Windows and Linux, tap Caps Lock for Escape or hold it for the Ctrl layer. Caps+H/J/K/L moves the cursor, and Caps+arrows controls volume and track playback.
- Caps+Alt+H/J/K/L sends Win/Super+Left/Down/Up/Right for tiling, and Caps+Alt+F sends F11. The other mapped keys send Ctrl+Alt+key. Plain Alt is reserved for zellij shortcuts in Alacritty.
- Windows uses [the AutoHotkey v1 script](autohotkey/capslock_remap_vim.ahk). Linux uses [the keyd keyboard config](etc/keyd/default.conf), where Caps+Space enters the Linux-only `space_mode` layer.
- On Linux, either Trackman Marble side button acts as middle click. Hold either button and move the ball to scroll in X11. The [keyd mouse config](etc/keyd/trackman.conf) remaps the buttons, and the [Xorg config](etc/X11/xorg.conf.d/40-button-scroll.conf) enables libinput button scrolling.
- [The Linux bootstrap](sh/bootstrap.sh) installs the keyd and Xorg configs and sets Super+arrow tiling shortcuts in Xfce. Cinnamon already uses Super+arrows.
