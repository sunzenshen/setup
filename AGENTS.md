# Agent guide for this repo

This repo sets up a new machine: `windows/bootstrap.ps1` for Windows 10/11 and
`sh/bootstrap.sh` for Linux Mint and Parrot OS. Use this guide when asked to
evaluate, add, or change an app or a default. `autohotkey/AGENTS.md` covers the
Caps Lock script itself.

The step-by-step procedure for adding an app is the `add-app` skill in
`.claude/skills/add-app/SKILL.md`; agents without skill support can read that
file directly.

## Ask before you change

- Ask before adding or removing anything in a package list. Propose the change
  with a one-line reason per app.
- Before running a bootstrap on the owner's machine, say what it will change
  there (shortcuts, autostart entries, running processes, settings).
- Inventory first when evaluating a machine: `winget list`, the Startup folder,
  HKCU/HKLM Run keys and logon scheduled tasks on Windows; `apt list --installed`
  and `flatpak list` on Linux. Compare against the lists in the scripts.
- Look for second copies too: `Get-Command <tool> -All`, `~\.cargo\bin`, and
  the order of the user and machine PATH. `winget list` does not show a
  cargo-built or hand-unzipped copy that shadows the winget one.
- An autostart entry is "new" only against a baseline. If there is none, list
  them all and say so.

## Evaluating a new app

Answer these before proposing it:

1. Where does it come from? Prefer the system package source (winget with an
   exact ID, apt, then Flathub). A direct download needs a pinned or
   checksum-verified release: keyd is pinned to a tag; MarbleScroll, Neovim
   and the Nerd Font on Linux are checked against the SHA-256 published with
   the release (this catches a bad download, not a compromised release).
   rustup's own installer over HTTPS is the one accepted exception.
2. Is it work-safe? See the profiles below. If unsure, ask; do not guess.
3. Does it need admin, a reboot, a service, or an autostart entry? Say so.
4. Does it self-update? If it does (rustup), keep it out of the package
   upgrade loop and use its own updater.
5. Is there a counterpart on the other OS? Keep the two bootstraps aligned
   where it makes sense, and say when one side is left out and why.
6. Does it already exist on the machine from another installer or path? Take
   over the existing install (keep its arguments and settings, remove the old
   autostart) instead of adding a second copy.

## Profiles

- The default must be safe for a work computer.
- `-Personal` (Windows) adds what stays off a work computer. Today that is
  AutoHotkey with the Caps Lock startup step, Signal, Discord and Steam. AutoHotkey is banned
  at the owner's workplace: without `-Personal` nothing may install, start, or
  modify anything AutoHotkey-related.
- Chat apps, game launchers, and anything that hooks input or looks like
  automation to endpoint security belong in the personal profile unless the
  owner says otherwise. MarbleScroll and KeePass are deliberately in the
  default.
- `--personal` (Linux) adds Signal and Steam. keyd is deliberately in the
  Linux default: the owner wants it on every Linux machine, unlike AutoHotkey
  on Windows.

## How the bootstraps must behave

- Re-runnable. Every step checks first and changes only what is missing or
  out of date. A second run must end with "Nothing to do".
- Every change is reported through `Add-Change` / `changed` so the summary is
  the full list of what happened.
- Never overwrite a setting the user already has (Git config, existing editor
  config). Fill in only what is unset. Back up before replacing a directory.
- A failed or partial download must never replace a good file. Download to a
  temporary name, verify, then move into place.
- A missing or failing optional package is a warning, not a fatal error.
- Run as the normal user. The Windows script refuses an elevated prompt.
- Windows settings changes go behind `-Tweaks`, are per-user (HKCU) only, and
  are listed one per line.

## Windows specifics

- Keep the script compatible with Windows PowerShell 5.1 and clean under
  PSScriptAnalyzer (errors and warnings fail CI).
  - Functions named with `Set-`, `New-`, `Remove-`, `Start-`, `Stop-`,
    `Update-` or `Reset-` trigger a ShouldProcess warning; plural nouns
    trigger another. Follow the existing `Install-<SingularNoun>` pattern.
  - `$PSScriptRoot` is empty in a `param()` default on 5.1; resolve paths in
    the body.
  - Native tools that write progress to stderr (rustup, git) become error
    records under `$ErrorActionPreference = 'Stop'` when stderr is
    redirected. Check `$LASTEXITCODE` instead.
- A tool just installed by winget is not on the current session's PATH. Look
  it up by its install path (see `Find-GitExe`, `Find-AutoHotkeyExe`).
- winget exit codes that are not failures are handled explicitly (no update
  available, installer type mismatch). Add new ones the same way.
- `git config --get` also sees the system-level file that Git for Windows
  writes (`init.defaultBranch`, `core.autocrlf`, `credential.helper`), so the
  installer's values win over the script's defaults.
- After the way PowerShell 7 is installed changes (MSI to MSIX), running apps
  keep the old `pwsh.exe` path until they restart. If an agent's PowerShell
  tool fails, say so and use `powershell.exe` or Git Bash.
- PSScriptAnalyzer is not on a fresh machine. Lint locally with
  `Install-Module PSScriptAnalyzer -Scope CurrentUser` (ask first), or say
  that only CI linted the change.
- Do not write a Windows PowerShell 5.1 profile: a fresh machine blocks
  profile scripts there. Profile additions go to the PowerShell 7 profile
  through `Add-ProfileBlock`, keyed on a marker line.

## Linux specifics

- Keep `sh/bootstrap.sh` clean under shellcheck and `set -Eeuo pipefail`.
- Packages missing from a distro's repos are reported and skipped.
- Root-owned config files go through `install_root_file`, which backs up the
  old file.
- Release downloads go through `fetch` and then `verify_release_asset`
  before anything is unpacked.
- Git runs `core.editor` directly: shell aliases and the PATH line in
  `~/.bash_aliases` do not apply. The default is `vi`, a real command, and
  `register_vi_alternative` points it at Neovim with `update-alternatives`
  (the distro's vi stays as the fallback; a manual choice is left alone).
- A Windows checkout has CRLF line endings in `sh/`; test from a Linux
  checkout, not through `/mnt/c` in WSL.

## Testing a change

- Test on a real machine, not only CI. CI checks parsing and lint only.
- Run with `-NoUpgrade` / `--no-upgrade` first, then a full run, then a
  repeat run to confirm it reports nothing to do. On a personal machine use
  `-Personal -Tweaks`, and run once without `-Personal`.
- Prove nothing restarted: before and after each run, record the Startup
  shortcuts (target, arguments, modified time), the HKCU/HKLM Run values and
  the AutoHotkey and MarbleScroll process IDs with start times, and diff them.
- Remove anything a test moved aside or left behind (for example under
  `%LOCALAPPDATA%\setup-bootstrap`), or report it.
- To test a fresh install of something already installed, move its folders
  aside and restore them afterwards rather than uninstalling. Uninstalling
  rustup, for example, deletes every cargo-installed tool.
- Verify the result works, not only that the installer exited 0 (build a
  hello-world, start the app headless, read back the setting).
- Report what was not tested.

## Privacy

- This repo is public. No credentials, tokens, hostnames, or private paths.
- Private or machine-specific steps go in `%USERPROFILE%\.setup-local.ps1`,
  which the Windows bootstrap runs if present. The repo must not name,
  download, or call anything private.
- The owner's Git name and email in `sh/bootstrap.sh` are there on purpose.

## Git workflow

- Work on a branch and open a pull request to `master`. Do not push to
  `master` directly, and do not merge; the owner merges.
- Update `README.md` when a switch or a visible behavior changes.
