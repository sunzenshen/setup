Vague setup notes in case I need to set up everything again after a hard drive failure.

vimrc
-----

My local .vimrc files.  I'm trying to avoid unnecessary yak-shaving by rolling with whatever comes with [spf13](http://vim.spf13.com/).

## Keyboard and mouse layout

- On Windows and Linux, tap Caps Lock for Escape or hold it for the Ctrl layer. Caps+H/J/K/L moves the cursor, and Caps+arrows controls volume and track playback.
- Caps+Alt+H/J/K/L sends Win/Super+Left/Down/Up/Right for tiling, and Caps+Alt+F sends F11. The other mapped keys send Ctrl+Alt+key. Plain Alt is reserved for zellij shortcuts in Alacritty.
- Windows uses [the AutoHotkey v2 script](autohotkey/capslock_remap_vim.ahk). Linux uses [the keyd keyboard config](etc/keyd/default.conf), where Caps+Space enters the Linux-only `space_mode` layer.
- On Linux and Windows, either Trackman Marble side button acts as middle click. On Windows this is done by [MarbleScroll](https://github.com/sunzenshen/CursedMarbleScroll), not the AHK script. Hold either button and move the ball to scroll in X11. The [keyd mouse config](etc/keyd/trackman.conf) remaps the buttons, and the [Xorg config](etc/X11/xorg.conf.d/40-button-scroll.conf) enables libinput button scrolling.
- [The Linux bootstrap](sh/bootstrap.sh) installs the keyd and Xorg configs and sets Super+arrow tiling shortcuts in Xfce. Cinnamon already uses Super+arrows.
- [The Windows bootstrap](windows/bootstrap.ps1) installs the usual apps with winget, Rust through rustup, the LazyVim starter config, `vi`/`vim` aliases in the PowerShell 7 profile, and the latest MarbleScroll release with "Start with Windows" on. The default is meant to be safe for a work computer; add `-Personal` to also install AutoHotkey with the Caps Lock script at login, Signal, Discord and Steam. Run it as your normal user and re-run it any time to upgrade: `powershell -ExecutionPolicy Bypass -File windows\bootstrap.ps1` (add `-NoUpgrade` to only install what is missing, and `-Tweaks` to also apply per-user Windows settings: Explorer shows extensions and hidden files, dark mode, fastest key repeat, mouse acceleration off). It also fills in unset Git defaults, asking for your name and email if Git has none, and finally runs `%USERPROFILE%\.setup-local.ps1` if you have one, for machine-specific steps.
- On a new Windows machine without Git, download and run the bootstrap in one line from PowerShell: `irm https://raw.githubusercontent.com/sunzenshen/setup/master/windows/bootstrap.ps1 -OutFile $env:TEMP\bootstrap.ps1; powershell -ExecutionPolicy Bypass -File $env:TEMP\bootstrap.ps1`
