<#
.SYNOPSIS
    Fresh-install / upgrade bootstrap for Windows 10 and 11.

.DESCRIPTION
    Run as your normal user, NOT from an elevated prompt (winget asks for
    elevation itself when a package needs it):

        powershell -ExecutionPolicy Bypass -File windows\bootstrap.ps1 [-NoUpgrade]

    Re-runnable: each step checks first and only installs or changes what is
    missing or out of date, then prints a summary of what changed.
    By default it also upgrades the listed winget packages and MarbleScroll.
    -NoUpgrade: only install what is missing (quick, no upgrades).

    Works from a checkout of this repo, or standalone (it then downloads the
    AutoHotkey script from GitHub).
#>
[CmdletBinding()]
param(
    [switch]$NoUpgrade
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'   # Invoke-WebRequest is very slow with the progress bar on 5.1

# --- Settings --------------------------------------------------------------
# winget package IDs (exact). Unknown IDs are reported and skipped, not fatal.
$WingetPackages = @(
    'Git.Git'
    'AutoHotkey.AutoHotkey'          # v2
    'Alacritty.Alacritty'
    'Zellij.Zellij'
    'Neovim.Neovim'
    'DEVCOM.JetBrainsMonoNerdFont'
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

$script:Upgrade = -not $NoUpgrade
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
    $common = @('--exact', '--source', 'winget', '--silent', '--disable-interactivity',
        '--accept-source-agreements', '--accept-package-agreements')
    foreach ($id in $WingetPackages) {
        if (Test-WingetInstalled $id) {
            if (-not $script:Upgrade) { Write-Info "$id already installed."; continue }
            & winget upgrade --id $id @common | Out-Host
            if ($LASTEXITCODE -eq 0) { Add-Change "winget upgraded: $id" }
            elseif ($LASTEXITCODE -eq $noUpdateAvailable) { Write-Info "$id is up to date." }
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

    # Same value the tray menu's "Start with Windows" toggle writes.
    $want = '"{0}"' -f $exe
    $current = (Get-ItemProperty -Path $RunKey -Name MarbleScroll -ErrorAction SilentlyContinue)
    if (-not $current -or $current.MarbleScroll -ne $want) {
        if (-not (Test-Path $RunKey)) { New-Item -Path $RunKey -Force | Out-Null }
        New-ItemProperty -Path $RunKey -Name MarbleScroll -Value $want -PropertyType String -Force | Out-Null
        Add-Change "MarbleScroll set to start with Windows ($want)"
    } else {
        Write-Info 'MarbleScroll already starts with Windows.'
    }

    if (@(Get-Process -Name MarbleScroll -ErrorAction SilentlyContinue).Count -eq 0) {
        Start-Process -FilePath $exe -WorkingDirectory $MarbleScrollDir
        Add-Change 'started MarbleScroll'
    } else {
        Write-Info 'MarbleScroll is already running.'
    }
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
    Install-AhkStartup
    Install-MarbleScroll
    Write-Summary
}

# Allow dot-sourcing for testing without running anything.
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-Bootstrap
}
