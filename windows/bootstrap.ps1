<#
.SYNOPSIS
    Fresh-install / upgrade bootstrap for Windows 10 and 11.

.DESCRIPTION
    Run as your normal user, NOT from an elevated prompt (winget asks for
    elevation itself when a package needs it):

        powershell -ExecutionPolicy Bypass -File windows\bootstrap.ps1 [-NoUpgrade] [-Tweaks] [-Personal]

    Re-runnable: each step checks first and only installs or changes what is
    missing or out of date, then prints a summary of what changed.
    By default it also upgrades the listed winget packages and MarbleScroll.
    -NoUpgrade: only install what is missing (quick, no upgrades).
    -Personal:  also install what stays off a work computer: AutoHotkey with
                the Caps Lock remap at login, and Signal. Without it nothing
                AutoHotkey-related is installed, started or changed.
    -Tweaks:    also apply per-user Windows settings (Explorer shows extensions
                and hidden files and opens to This PC, dark mode, shortest key
                repeat delay, mouse acceleration off).

    Works from a checkout of this repo, or standalone (it then downloads the
    AutoHotkey script from GitHub).

    If %USERPROFILE%\.setup-local.ps1 exists it is run at the end, for
    machine-specific or private steps that do not belong in this repo.
#>
[CmdletBinding()]
param(
    [switch]$NoUpgrade,
    [switch]$Tweaks,
    [switch]$Personal
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'   # Invoke-WebRequest is very slow with the progress bar on 5.1

# --- Settings --------------------------------------------------------------
# winget package IDs (exact). Unknown IDs are reported and skipped, not fatal.
# This default list is meant to be safe for a work computer.
$WingetPackages = @(
    'Git.Git'
    'Alacritty.Alacritty'
    'Zellij.Zellij'
    'Neovim.Neovim'
    'DEVCOM.JetBrainsMonoNerdFont'
    'Microsoft.WindowsTerminal'
    'Microsoft.PowerShell'
    'GitHub.cli'
    'JesseDuffield.lazygit'
    'Microsoft.VisualStudioCode'
    'DominikReichl.KeePass'
    '7zip.7zip'
)
# Only with -Personal: things that do not belong on a work computer.
$PersonalPackages = @(
    'AutoHotkey.AutoHotkey'          # v2
    'OpenWhisperSystems.Signal'
)
$RepoRawUrl       = 'https://raw.githubusercontent.com/sunzenshen/setup/master'
$AhkScriptRel     = 'autohotkey/capslock_remap_vim.ahk'
$AhkScriptName    = 'capslock_remap_vim'
$MarbleScrollRepo = 'sunzenshen/CursedMarbleScroll'
# Fixed path on purpose: MarbleScroll's saved tray settings are keyed on the exe path.
$MarbleScrollDir  = Join-Path $env:LOCALAPPDATA 'Programs\MarbleScroll'
$DataDir          = Join-Path $env:LOCALAPPDATA 'setup-bootstrap'
$RunKey           = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'

$LocalHook        = Join-Path $env:USERPROFILE '.setup-local.ps1'

$script:Upgrade = -not $NoUpgrade
$script:ApplyTweaks = [bool]$Tweaks
$script:Personal = [bool]$Personal
$script:Changes = New-Object System.Collections.Generic.List[string]

# --- Helpers ---------------------------------------------------------------
function Write-Step { param([string]$Message) Write-Information "`n==> $Message" }
function Write-Info { param([string]$Message) Write-Information "    $Message" }
function Add-Change { param([string]$Message) $script:Changes.Add($Message); Write-Info $Message }

# Download URL to DEST. DEST is only replaced when the content changed, so a
# failed or partial download never clobbers a good copy.
# Returns $true if DEST changed.
function Save-Url {
    param([string]$Url, [string]$Dest)
    $dir = Split-Path -Parent $Dest
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $tmp = "$Dest.download"
    try {
        Invoke-WebRequest -Uri $Url -OutFile $tmp -UseBasicParsing
        if ((Get-Item $tmp).Length -eq 0) { throw 'empty response' }
    } catch {
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
        if (Test-Path $Dest) {
            Write-Warning "download failed ($($_.Exception.Message)), using existing $Dest"
            return $false
        }
        throw "download failed: $Url ($($_.Exception.Message))"
    }
    if ((Test-Path $Dest) -and ((Get-FileHash $tmp).Hash -eq (Get-FileHash $Dest).Hash)) {
        Remove-Item $tmp -Force
        return $false
    }
    Move-Item $tmp $Dest -Force
    return $true
}

function Test-WingetInstalled {
    param([string]$Id)
    & winget list --id $Id --exact --accept-source-agreements --disable-interactivity | Out-Null
    return ($LASTEXITCODE -eq 0)
}

# --- Steps -----------------------------------------------------------------
function Test-Preflight {
    Write-Step 'Preflight'
    if ([Environment]::OSVersion.Platform -ne 'Win32NT') { throw 'This script is for Windows.' }
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $isAdmin = (New-Object Security.Principal.WindowsPrincipal $identity).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($isAdmin) {
        # Startup entries and per-user installs must land in the normal user's profile,
        # and apps started from here would run elevated.
        throw 'Run this as your normal user, not from an elevated prompt.'
    }
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw 'winget not found. Install "App Installer" from the Microsoft Store (or update Windows), then re-run.'
    }
    # Windows PowerShell 5.1 can default to TLS 1.0/1.1, which GitHub rejects.
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    Write-Info "winget $(& winget --version)"
}

function Install-PackageList {
    Write-Step 'winget packages'
    $noUpdateAvailable = -1978335189   # 0x8A15002B APPINSTALLER_CLI_ERROR_UPDATE_NOT_APPLICABLE
    $installerMismatch = -1978335090   # 0x8A15008E newer version uses a different install technology
    $common = @('--exact', '--source', 'winget', '--silent', '--disable-interactivity',
        '--accept-source-agreements', '--accept-package-agreements')
    $packages = $WingetPackages
    if ($script:Personal) { $packages += $PersonalPackages }
    else { Write-Info "Work-safe profile; skipping (add -Personal to include): $($PersonalPackages -join ', ')" }
    foreach ($id in $packages) {
        if (Test-WingetInstalled $id) {
            if (-not $script:Upgrade) { Write-Info "$id already installed."; continue }
            & winget upgrade --id $id @common | Out-Host
            if ($LASTEXITCODE -eq 0) { Add-Change "winget upgraded: $id" }
            elseif ($LASTEXITCODE -eq $noUpdateAvailable) { Write-Info "$id is up to date." }
            elseif ($LASTEXITCODE -eq $installerMismatch) {
                Write-Info "$id has an update, but it was installed with a different installer type; winget cannot upgrade it in place (uninstall and re-run to switch)."
            }
            else { Write-Warning "winget upgrade $id failed (exit code $LASTEXITCODE)" }
            continue
        }
        & winget show --id $id --exact --source winget --disable-interactivity | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "not in the winget source, skipped: $id"
            continue
        }
        & winget install --id $id @common | Out-Host
        if ($LASTEXITCODE -eq 0) { Add-Change "winget installed: $id" }
        else { Write-Warning "winget install $id failed (exit code $LASTEXITCODE)" }
    }
}

function Find-AutoHotkeyExe {
    $dirs = @()
    foreach ($key in 'HKLM:\SOFTWARE\AutoHotkey', 'HKCU:\SOFTWARE\AutoHotkey') {
        $prop = Get-ItemProperty -Path $key -Name InstallDir -ErrorAction SilentlyContinue
        if ($prop) { $dirs += $prop.InstallDir }
    }
    $dirs += (Join-Path $env:ProgramFiles 'AutoHotkey')
    $dirs += (Join-Path $env:LOCALAPPDATA 'Programs\AutoHotkey')
    foreach ($dir in $dirs) {
        $exe = Join-Path $dir 'v2\AutoHotkey64.exe'
        if (Test-Path $exe) { return $exe }
    }
    return $null
}

# The script from the local checkout if present, else downloaded from GitHub.
# Returns @{ Path; Changed }.
function Get-AhkScript {
    if ($PSScriptRoot) {
        $local = Join-Path (Split-Path -Parent $PSScriptRoot) ($AhkScriptRel -replace '/', '\')
        if (Test-Path $local) { return @{ Path = (Resolve-Path $local).Path; Changed = $false } }
    }
    $dest = Join-Path $DataDir ($AhkScriptRel -replace '/', '\')
    $changed = Save-Url "$RepoRawUrl/$AhkScriptRel" $dest
    if ($changed) { Add-Change "downloaded $AhkScriptRel -> $dest" }
    return @{ Path = $dest; Changed = $changed }
}

function Install-AhkStartup {
    Write-Step 'AutoHotkey Caps Lock remap'
    $ahkExe = Find-AutoHotkeyExe
    if (-not $ahkExe) {
        Write-Warning 'AutoHotkey v2 (AutoHotkey64.exe) not found; skipping the Caps Lock remap.'
        return
    }
    $ahk = Get-AhkScript
    $restart = $ahk.Changed

    # Startup shortcut. Reuse an existing one for this script (e.g. an old one that
    # points at the compiled .exe) so two copies never run side by side.
    $startupDir = [Environment]::GetFolderPath('Startup')
    $shell = New-Object -ComObject WScript.Shell
    $lnkPath = Join-Path $startupDir "$AhkScriptName.lnk"
    foreach ($file in Get-ChildItem -Path $startupDir -Filter '*.lnk') {
        $existing = $shell.CreateShortcut($file.FullName)
        if ("$($existing.TargetPath) $($existing.Arguments)" -like "*$AhkScriptName*") {
            $lnkPath = $file.FullName
            break
        }
    }
    $lnk = $shell.CreateShortcut($lnkPath)
    $wantArgs = '"{0}"' -f $ahk.Path
    if ($lnk.TargetPath -ne $ahkExe -or $lnk.Arguments -ne $wantArgs) {
        $lnk.TargetPath = $ahkExe
        $lnk.Arguments = $wantArgs
        $lnk.WorkingDirectory = Split-Path -Parent $ahk.Path
        $lnk.Description = 'Caps Lock remap (github.com/sunzenshen/setup)'
        $lnk.Save()
        Add-Change "Startup shortcut $lnkPath -> $ahkExe $wantArgs"
        $restart = $true
    } else {
        Write-Info "Startup shortcut is up to date ($lnkPath)."
    }

    # A previously compiled copy would double every hotkey.
    $compiled = @(Get-Process -Name $AhkScriptName -ErrorAction SilentlyContinue)
    if ($compiled.Count -gt 0) {
        $compiled | Stop-Process -Force
        Add-Change "stopped old compiled $AhkScriptName.exe"
        $restart = $true
    }
    $running = @(Get-CimInstance Win32_Process -Filter "Name LIKE 'AutoHotkey%'" |
            Where-Object { $_.CommandLine -like "*$AhkScriptName.ahk*" })
    if ($restart -or $running.Count -eq 0) {
        # /restart replaces a running instance of the same script without prompting.
        Start-Process -FilePath $ahkExe -ArgumentList '/restart', $wantArgs
        Add-Change "started $AhkScriptName.ahk"
    } else {
        Write-Info "$AhkScriptName.ahk is already running."
    }
}

function Install-MarbleScroll {
    Write-Step 'MarbleScroll'
    $exe = Join-Path $MarbleScrollDir 'MarbleScroll.exe'
    $versionFile = Join-Path $MarbleScrollDir 'version.txt'
    $installed = $null
    if ((Test-Path $exe) -and (Test-Path $versionFile)) { $installed = (Get-Content $versionFile -TotalCount 1).Trim() }

    if ($installed -and -not $script:Upgrade) {
        Write-Info "MarbleScroll $installed already installed."
    } else {
        $release = $null
        try {
            $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$MarbleScrollRepo/releases/latest" `
                -Headers @{ 'User-Agent' = 'setup-bootstrap'; 'Accept' = 'application/vnd.github+json' }
        } catch {
            if (-not $installed) { throw "could not query the latest MarbleScroll release: $($_.Exception.Message)" }
            Write-Warning "could not query the latest MarbleScroll release, keeping $installed`: $($_.Exception.Message)"
        }
        if ($release -and $release.tag_name -eq $installed) {
            Write-Info "MarbleScroll $installed is up to date."
        } elseif ($release) {
            $tag = $release.tag_name
            $zipAsset = $release.assets | Where-Object { $_.name -like 'MarbleScroll-*.zip' } | Select-Object -First 1
            $sumAsset = $release.assets | Where-Object { $_.name -eq 'SHA256SUMS.txt' } | Select-Object -First 1
            if (-not $zipAsset -or -not $sumAsset) { throw "MarbleScroll release $tag has no ZIP or SHA256SUMS.txt asset" }

            $work = Join-Path $DataDir "marblescroll-$tag"
            if (Test-Path $work) { Remove-Item $work -Recurse -Force }
            New-Item -ItemType Directory -Path $work -Force | Out-Null
            try {
                $zip = Join-Path $work $zipAsset.name
                $sums = Join-Path $work 'SHA256SUMS.txt'
                Save-Url $zipAsset.browser_download_url $zip | Out-Null
                Save-Url $sumAsset.browser_download_url $sums | Out-Null

                # Lines look like "<sha256>  <file name>". This catches a corrupt or
                # truncated download; it is the same trust as the release itself.
                $expected = $null
                foreach ($line in Get-Content $sums) {
                    $parts = $line.Trim() -split '\s+', 2
                    if ($parts.Count -eq 2 -and $parts[1].TrimStart('*') -eq $zipAsset.name) { $expected = $parts[0] }
                }
                if (-not $expected) { throw "SHA256SUMS.txt has no entry for $($zipAsset.name)" }
                $actual = (Get-FileHash -Path $zip -Algorithm SHA256).Hash
                if ($actual -ne $expected) { throw "MarbleScroll ZIP SHA256 mismatch (expected $expected, got $actual)" }

                $unpacked = Join-Path $work 'unpacked'
                Expand-Archive -Path $zip -DestinationPath $unpacked
                if (-not (Test-Path (Join-Path $unpacked 'MarbleScroll.exe'))) { throw 'MarbleScroll.exe is missing from the release ZIP' }

                # The exe is locked while it runs.
                $procs = @(Get-Process -Name MarbleScroll -ErrorAction SilentlyContinue)
                if ($procs.Count -gt 0) {
                    $procs | Stop-Process -Force
                    $procs | Wait-Process -Timeout 10 -ErrorAction SilentlyContinue
                }
                New-Item -ItemType Directory -Path $MarbleScrollDir -Force | Out-Null
                Copy-Item -Path (Join-Path $unpacked '*') -Destination $MarbleScrollDir -Recurse -Force
                Set-Content -Path $versionFile -Value $tag -Encoding ASCII
                if ($installed) { Add-Change "MarbleScroll upgraded $installed -> $tag" }
                else { Add-Change "MarbleScroll $tag installed to $MarbleScrollDir" }
            } finally {
                Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    if (-not (Test-Path $exe)) { return }

    # Settings are saved under %LOCALAPPDATA%\MarbleScroll; keep one copy before
    # the first switch to the managed install path.
    $settingsDir = Join-Path $env:LOCALAPPDATA 'MarbleScroll'
    $settingsBackup = Join-Path $DataDir 'MarbleScroll-settings-backup'
    if ((Test-Path $settingsDir) -and -not (Test-Path $settingsBackup)) {
        Copy-Item -Path $settingsDir -Destination $settingsBackup -Recurse -Force
        Add-Change "backed up MarbleScroll settings to $settingsBackup"
    }

    # An older MarbleScroll elsewhere (e.g. a dev build) may autostart through a
    # Startup shortcut or its own Run entry. Take over its command-line arguments
    # and remove the old autostart so only one copy ever starts.
    $mArgs = ''
    $startupDir = [Environment]::GetFolderPath('Startup')
    $shell = New-Object -ComObject WScript.Shell
    foreach ($file in @(Get-ChildItem -Path $startupDir -Filter '*.lnk')) {
        $existing = $shell.CreateShortcut($file.FullName)
        if ($existing.TargetPath -like '*\MarbleScroll.exe' -and $existing.TargetPath -ne $exe) {
            if ($existing.Arguments) { $mArgs = $existing.Arguments }
            Remove-Item $file.FullName -Force
            Add-Change "removed old MarbleScroll Startup shortcut $($file.FullName) (was $($existing.TargetPath) $($existing.Arguments))"
        }
    }
    $current = (Get-ItemProperty -Path $RunKey -Name MarbleScroll -ErrorAction SilentlyContinue)
    if ($current -and -not $mArgs -and $current.MarbleScroll -match '^"([^"]+)"\s*(.*)$' -and $Matches[1] -eq $exe) {
        $mArgs = $Matches[2].Trim()
    }

    # Same value the tray menu's "Start with Windows" toggle writes (plus any arguments).
    $want = ('"{0}" {1}' -f $exe, $mArgs).Trim()
    if (-not $current -or $current.MarbleScroll -ne $want) {
        if (-not (Test-Path $RunKey)) { New-Item -Path $RunKey -Force | Out-Null }
        New-ItemProperty -Path $RunKey -Name MarbleScroll -Value $want -PropertyType String -Force | Out-Null
        Add-Change "MarbleScroll set to start with Windows ($want)"
    } else {
        Write-Info 'MarbleScroll already starts with Windows.'
    }

    # Stop copies running from any other path, then make sure ours is running.
    $running = @(Get-Process -Name MarbleScroll -ErrorAction SilentlyContinue)
    $others = @($running | Where-Object { $_.Path -ne $exe })
    if ($others.Count -gt 0) {
        $others | Stop-Process -Force
        $others | Wait-Process -Timeout 10 -ErrorAction SilentlyContinue
        Add-Change 'stopped MarbleScroll running from another path'
    }
    if (@($running | Where-Object { $_.Path -eq $exe }).Count -eq 0) {
        $startArgs = @{ FilePath = $exe; WorkingDirectory = $MarbleScrollDir }
        if ($mArgs) { $startArgs.ArgumentList = $mArgs }
        Start-Process @startArgs
        Add-Change 'started MarbleScroll'
    } else {
        Write-Info 'MarbleScroll is already running.'
    }
}

function Find-GitExe {
    $cmd = Get-Command git -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    # Just installed: not on this session's PATH yet.
    $exe = Join-Path $env:ProgramFiles 'Git\cmd\git.exe'
    if (Test-Path $exe) { return $exe }
    return $null
}

# Rust comes from rustup, which also keeps itself and the toolchains up to date,
# so it is not in the winget upgrade list.
function Install-Rust {
    Write-Step 'Rust (rustup)'
    $rustup = Join-Path $env:USERPROFILE '.cargo\bin\rustup.exe'
    if (-not (Test-Path $rustup)) {
        & winget install --id Rustlang.Rustup --exact --source winget --silent --disable-interactivity `
            --accept-source-agreements --accept-package-agreements | Out-Host
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path $rustup)) {
            Write-Warning "rustup install failed (exit code $LASTEXITCODE)"
            return
        }
        Add-Change 'installed rustup and the stable Rust toolchain'
    } elseif ($script:Upgrade) {
        # rustup reports progress on stderr; keep that from becoming an error record on 5.1.
        $previous = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try { $output = (& $rustup update 2>&1 | Out-String) } finally { $ErrorActionPreference = $previous }
        if ($LASTEXITCODE -ne 0) { Write-Warning "rustup update failed (exit code $LASTEXITCODE)" }
        elseif ($output -match '(?m)\bupdated\b') { Add-Change 'rustup updated Rust' }
        else { Write-Info 'Rust is up to date.' }
    } else {
        Write-Info 'rustup already installed.'
    }

    # The default (MSVC) toolchain cannot link without the Visual C++ build tools.
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    $vcTools = $null
    if (Test-Path $vswhere) {
        $vcTools = & $vswhere -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    }
    if (-not $vcTools) {
        Write-Warning 'Visual C++ build tools not found; Rust cannot link programs until they are installed: winget install Microsoft.VisualStudio.2022.BuildTools --override "--add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --passive --wait"'
    }
}

# LazyVim starter config, only when Neovim has no LazyVim config yet.
function Install-LazyVim {
    Write-Step 'LazyVim'
    $config = Join-Path $env:LOCALAPPDATA 'nvim'
    if ((Test-Path (Join-Path $config 'lazy-lock.json')) -or (Test-Path (Join-Path $config 'lua\config\lazy.lua'))) {
        Write-Info 'LazyVim config already present; leaving it alone.'
        return
    }
    $git = Find-GitExe
    if (-not $git) { Write-Warning 'git not found; skipping LazyVim.'; return }

    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    foreach ($dir in $config, (Join-Path $env:LOCALAPPDATA 'nvim-data')) {
        if (Test-Path $dir) {
            Move-Item -Path $dir -Destination "$dir.bak.$stamp"
            Write-Info "Backed up $dir -> $dir.bak.$stamp"
        }
    }
    & $git clone --quiet --depth 1 https://github.com/LazyVim/starter $config
    if ($LASTEXITCODE -ne 0) { Write-Warning "LazyVim clone failed (exit code $LASTEXITCODE)"; return }
    Remove-Item (Join-Path $config '.git') -Recurse -Force
    Add-Change 'installed LazyVim starter config (plugins install on the first nvim start)'
}

# Append a block to a file once, keyed on an exact marker line.
function Add-ProfileBlock {
    param([string]$File, [string]$Marker, [string]$Body)
    if ((Test-Path $File) -and (@(Get-Content $File) -contains $Marker)) {
        Write-Info "$Marker already present in $File."
        return
    }
    $dir = Split-Path -Parent $File
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Add-Content -Path $File -Value "`r`n$Marker`r`n$Body" -Encoding UTF8
    Add-Change "added '$Marker' to $File"
}

# PowerShell 7 profile only: Windows PowerShell 5.1 blocks profile scripts by
# default, so a profile there would print an error in every new window.
function Install-ShellProfile {
    Write-Step 'PowerShell profile'
    $documents = [Environment]::GetFolderPath('MyDocuments')
    $profilePath = Join-Path $documents 'PowerShell\Microsoft.PowerShell_profile.ps1'
    Add-ProfileBlock $profilePath '# Neovim Aliases' "Set-Alias vi nvim`r`nSet-Alias vim nvim"
}

# Fill in Git settings that are not set yet; never overwrite an existing value.
function Install-GitConfig {
    Write-Step 'Git defaults'
    $git = Find-GitExe
    if (-not $git) { Write-Warning 'git not found; skipping Git defaults.'; return }

    $defaults = [ordered]@{
        'init.defaultBranch' = 'main'
        'core.autocrlf'      = 'true'
        'credential.helper'  = 'manager'
    }
    foreach ($key in $defaults.Keys) {
        $value = & $git config --get $key
        if ($value) { Write-Info "$key = $value"; continue }
        & $git config --global $key $defaults[$key]
        Add-Change "git config --global $key $($defaults[$key])"
    }

    # Identity is asked for, not stored in this repo.
    foreach ($key in 'user.name', 'user.email') {
        if (& $git config --get $key) { Write-Info "$key is set."; continue }
        if (-not [Environment]::UserInteractive -or [Console]::IsInputRedirected) {
            Write-Warning "git $key is not set; run: git config --global $key <value>"
            continue
        }
        $answer = (Read-Host "    git $key (blank to skip)").Trim()
        if ($answer) {
            & $git config --global $key $answer
            Add-Change "git config --global $key set"
        }
    }
}

# Returns $true if the value was changed.
function Install-RegistryValue {
    param([string]$Path, [string]$Name, $Value, [string]$Type)
    $current = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
    if ($current -and "$($current.$Name)" -eq "$Value") { return $false }
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
    return $true
}

function Install-SettingTweak {
    Write-Step 'Windows settings'
    if (-not $script:ApplyTweaks) { Write-Info 'Skipped (run with -Tweaks to apply).'; return }

    $explorer = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    $theme = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
    $keyboard = 'HKCU:\Control Panel\Keyboard'
    $mouse = 'HKCU:\Control Panel\Mouse'
    $settings = @(
        @{ Label = 'Explorer: show file extensions';       Path = $explorer; Name = 'HideFileExt';          Value = 0;    Type = 'DWord' }
        @{ Label = 'Explorer: show hidden files';          Path = $explorer; Name = 'Hidden';               Value = 1;    Type = 'DWord' }
        @{ Label = 'Explorer: open to This PC';            Path = $explorer; Name = 'LaunchTo';             Value = 1;    Type = 'DWord' }
        @{ Label = 'Dark mode for apps';                   Path = $theme;    Name = 'AppsUseLightTheme';    Value = 0;    Type = 'DWord' }
        @{ Label = 'Dark mode for Windows';                Path = $theme;    Name = 'SystemUsesLightTheme'; Value = 0;    Type = 'DWord' }
        @{ Label = 'Keyboard: shortest repeat delay';      Path = $keyboard; Name = 'KeyboardDelay';        Value = '0';  Type = 'String' }
        @{ Label = 'Keyboard: fastest repeat rate';        Path = $keyboard; Name = 'KeyboardSpeed';        Value = '31'; Type = 'String' }
        @{ Label = 'Mouse: acceleration off (speed)';      Path = $mouse;    Name = 'MouseSpeed';           Value = '0';  Type = 'String' }
        @{ Label = 'Mouse: acceleration off (threshold 1)'; Path = $mouse;   Name = 'MouseThreshold1';      Value = '0';  Type = 'String' }
        @{ Label = 'Mouse: acceleration off (threshold 2)'; Path = $mouse;   Name = 'MouseThreshold2';      Value = '0';  Type = 'String' }
    )
    $changed = $false
    foreach ($s in $settings) {
        if (Install-RegistryValue -Path $s.Path -Name $s.Name -Value $s.Value -Type $s.Type) {
            Add-Change "setting: $($s.Label)"
            $changed = $true
        }
    }
    if ($changed) { Write-Info 'Sign out and back in for these settings to take full effect.' }
    else { Write-Info 'Windows settings are already applied.' }
}

# Machine-specific or private steps live outside this repo.
function Invoke-LocalHook {
    if (-not (Test-Path $LocalHook)) { return }
    Write-Step "Local hook ($LocalHook)"
    # In its own process, so an 'exit' or error in the hook cannot end this script early.
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $LocalHook | Out-Host
    if ($LASTEXITCODE -ne 0) { Write-Warning "local hook failed (exit code $LASTEXITCODE)" }
    else { Write-Info 'Local hook finished.' }
}

function Write-Summary {
    Write-Step 'Bootstrap complete.'
    if ($script:Changes.Count -gt 0) {
        Write-Info 'Changes made this run:'
        foreach ($change in $script:Changes) { Write-Information "      - $change" }
        Write-Info 'Open a new terminal to pick up PATH changes.'
    } else {
        Write-Info 'Nothing to do; everything was already set up.'
    }
}

function Invoke-Bootstrap {
    Test-Preflight
    Install-PackageList
    if ($script:Personal) { Install-AhkStartup }
    Install-MarbleScroll
    Install-Rust
    Install-LazyVim
    Install-ShellProfile
    Install-GitConfig
    Install-SettingTweak
    Invoke-LocalHook
    Write-Summary
}

# Allow dot-sourcing for testing without running anything.
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-Bootstrap
}
