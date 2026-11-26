---
name: add-app
description: Evaluate and add an application (or an app default) to this repo's Windows and Linux bootstrap scripts. Use when asked to install, add, evaluate, or remove an app, package, or tool in the setup, or to compare a machine's installed apps against the bootstrap lists.
---

# Add an app to the bootstrap

Read `AGENTS.md` at the repo root first; its rules apply here. This skill is the
step-by-step procedure.

## 1. Identify the package

Windows (run these, do not guess IDs):

```powershell
winget search "<name>" --source winget
winget show --id <Publisher.App> --exact --source winget
winget list --id <Publisher.App> --exact
```

- Use the exact ID from the `winget` source, never the `msstore` ID.
- From `winget show`, note the installer type, whether it needs elevation, and
  its dependencies.
- If `winget list` already shows the app from another installer (an `ARP\...`
  or `MSIX\...` ID, or a different install technology), say so: winget may not
  be able to upgrade it in place.

Linux:

```bash
apt-cache policy <package>      # is there an install candidate?
flatpak search <name>           # Flathub fallback
```

## 2. Choose the install pattern

Pick the first that fits.

| Pattern | Use when | Where it goes |
|---|---|---|
| winget list | The app is in the winget source | `$WingetPackages`, or `$PersonalPackages` if not work-safe |
| apt list | The app is in Mint's and Parrot's repos | `COMMON_PACKAGES` (or `PARROT_ONLY_PACKAGES`) |
| apt, else Flathub | Only some distros carry it | `APT_OR_FLATPAK` |
| Its own updater | The tool manages its own versions (rustup) | A dedicated `Install-<Name>` / `install_<name>` step, outside the upgrade loop |
| GitHub release | Not in any package source | A dedicated step modeled on `Install-MarbleScroll` (checksum-verified ZIP) or `install_neovim` (staged swap) |
| Config or default | A setting, alias, or config file | `Install-GitConfig`, `Add-ProfileBlock`, `Install-SettingTweak` (behind `-Tweaks`), `append_once`, `install_root_file` |

A dedicated step must: check before acting, report through `Add-Change` /
`changed`, warn instead of failing when the app is optional, and be called
from `Invoke-Bootstrap` / `main`.

## 3. Decide the profile

- Default list: safe on a work computer.
- `$PersonalPackages` (run with `-Personal`): chat apps, game launchers,
  AutoHotkey, and anything endpoint security may flag.
- Borderline (input hooks, VPNs, personal cloud sync, password managers,
  unsigned binaries): ask the owner.

## 4. Propose, then wait

Before editing a package list, show the owner:

- the exact package ID(s) and the pattern chosen,
- default or personal profile, and why,
- what it changes on the machine (admin prompt, autostart, service, PATH),
- the counterpart on the other OS, or why there is none.

Edit only after they approve.

## 5. Implement

- Add the ID to the right list, or write the dedicated step.
- Update the script's header help and `README.md` if a switch or visible
  behavior changed.
- Windows: stay PowerShell 5.1 compatible and PSScriptAnalyzer clean (see the
  naming and stderr notes in `AGENTS.md`).
- Linux: stay shellcheck clean.

## 6. Test on the machine

Tell the owner what the run will change first, then:

```powershell
powershell -ExecutionPolicy Bypass -File windows\bootstrap.ps1 -NoUpgrade
powershell -ExecutionPolicy Bypass -File windows\bootstrap.ps1
powershell -ExecutionPolicy Bypass -File windows\bootstrap.ps1
```

- Add `-Personal` when the app is in the personal list, and also run once
  without it to confirm the app is skipped.
- The last run must end with "Nothing to do".
- To test a fresh install of something already present, move its folders
  aside and restore them afterwards; do not uninstall.
- Confirm the app actually works (version command, a small real use), not
  only that the installer exited 0.

## 7. Ship

- Commit on a branch, push, and open a pull request to `master`. The owner
  merges.
- In the pull request, state what was tested, on which OS, and what was not.

## Removing an app

Removing an ID from a list stops future installs and upgrades; it does not
uninstall anything. Say so, and uninstall only if the owner asks.
