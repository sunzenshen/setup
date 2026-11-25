#!/usr/bin/env bash
#
# Fresh-install bootstrap for Linux Mint (22.x) and Parrot OS (Debian-based).
#
# Usage: ./sh/bootstrap.sh [--no-upgrade]   (run as your normal user, NOT with sudo)
#
# Re-runnable: each step checks first and only installs or changes what is missing
# or out of date, then prints a summary of what changed.
# By default it also upgrades system packages, Neovim and Rust so the machine
# always matches the latest version of this script.
# --no-upgrade: only install what is missing (quick, no upgrades or autoremove).

set -Eeuo pipefail
trap 'echo "ERROR: bootstrap failed at line $LINENO: $BASH_COMMAND" >&2' ERR

# --- Settings --------------------------------------------------------------
CACHE_DIR="$HOME/cache_bootstrap"
KEYD_VERSION="v2.6.0"   # pinned release tag; bump deliberately
REPO_RAW_URL="https://raw.githubusercontent.com/sunzenshen/setup/master"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
UPGRADE=1
CHANGES=()

# Packages wanted everywhere. Missing ones are reported and skipped, not fatal.
COMMON_PACKAGES=(
    ca-certificates git curl tar gzip unzip build-essential
    zbar-tools v4l-utils alacritty cinnamon timeshift flatpak xinput
    qemu-system-x86 libvirt-daemon-system libvirt-clients bridge-utils
    virt-manager qemu-guest-agent spice-vdagent
)
# Pentest tools: only on Parrot (they are in its repos, not Mint's).
PARROT_ONLY_PACKAGES=(burpsuite zaproxy)
# apt package -> Flathub fallback when the distro repos don't carry it.
declare -A APT_OR_FLATPAK=(
    [signal-desktop]=org.signal.Signal
)

# --- Helpers ---------------------------------------------------------------
log()  { printf '\n==> %s\n' "$*"; }
info() { printf '    %s\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
changed() { CHANGES+=("$*"); info "$*"; }

apt_get() { sudo DEBIAN_FRONTEND=noninteractive apt-get -y "$@"; }

# True if apt has an installable candidate for the package.
apt_has() {
    local cand
    cand="$(apt-cache policy "$1" 2>/dev/null | awk '/Candidate:/ {print $2}')"
    [[ -n "$cand" && "$cand" != "(none)" ]]
}

dpkg_installed() {
    # dpkg-query expands the Status field in its format string.
    # shellcheck disable=SC2016
    [[ "$(dpkg-query -W -f='${Status}' "$1" 2>/dev/null)" == "install ok installed" ]]
}

# Install packages that are missing and available; report unavailable ones instead of aborting.
apt_install_missing() {
    local todo=() unavailable=() p
    for p in "$@"; do
        if dpkg_installed "$p"; then continue
        elif apt_has "$p"; then todo+=("$p")
        else unavailable+=("$p"); fi
    done
    ((${#unavailable[@]})) && warn "not in this distro's repos, skipped: ${unavailable[*]}"
    if ((${#todo[@]})); then
        apt_get install "${todo[@]}"
        changed "apt installed: ${todo[*]}"
    else
        info "All available apt packages already installed."
    fi
}

ensure_flathub() {
    command -v flatpak >/dev/null || apt_get install flatpak
    flatpak remotes --columns=name 2>/dev/null | grep -qxF flathub && return
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}

# Download URL to DEST. DEST is only replaced when the content changed, so a
# failed or partial download never clobbers a good cached copy.
fetch() {
    local url="$1" dest="$2" tmp
    tmp="$(mktemp "$dest.XXXXXX")"
    if ! curl -fsSL --retry 3 -o "$tmp" "$url" || [[ ! -s "$tmp" ]]; then
        rm -f "$tmp"
        [[ -s "$dest" ]] || die "download failed: $url"
        warn "download failed, using cached $dest"
        return 0
    fi
    if cmp -s "$tmp" "$dest"; then rm -f "$tmp"; else mv "$tmp" "$dest"; fi
}

# Path to a repo file: the local checkout if present, else downloaded from GitHub.
repo_file() {
    local rel="$1" cached
    if [[ -f "$REPO_ROOT/$rel" ]]; then
        echo "$REPO_ROOT/$rel"
    else
        cached="$CACHE_DIR/repo/$rel"
        mkdir -p "$(dirname "$cached")"
        fetch "$REPO_RAW_URL/$rel" "$cached"
        echo "$cached"
    fi
}

# Install SRC to root-owned DEST if different (backing up the old one).
# Returns 0 if the file changed, 1 if it was already up to date.
install_root_file() {
    local src="$1" dest="$2"
    if sudo cmp -s "$src" "$dest" 2>/dev/null; then
        info "$dest is up to date."
        return 1
    fi
    if sudo test -e "$dest"; then
        sudo cp -a "$dest" "$dest.bak.$STAMP" || die "could not back up $dest"
        info "Backed up $dest -> $dest.bak.$STAMP"
    fi
    sudo install -D -m 0644 "$src" "$dest" || die "could not install $dest"
    info "Installed $dest"
}

# Append a block to a file once, keyed on an exact marker line.
append_once() {
    local file="$1" marker="$2" body="$3"
    touch "$file"
    if grep -qxF "$marker" "$file"; then
        info "$marker already present in $file."
    else
        printf '\n%s\n%s\n' "$marker" "$body" >> "$file"
        changed "added '$marker' to $file"
    fi
}

# --- Steps -----------------------------------------------------------------
preflight() {
    local arg
    for arg in "$@"; do
        case "$arg" in
            --no-upgrade) UPGRADE=0 ;;
            -h|--help) sed -n '3,11p' "${BASH_SOURCE[0]}"; exit 0 ;;
            *) die "unknown argument: $arg" ;;
        esac
    done
    [[ $EUID -ne 0 ]] || die "run as your normal user, not root/sudo (it uses sudo itself)."
    [[ -r /etc/os-release ]] || die "/etc/os-release not found."
    # Read the target machine's distro metadata at runtime.
    # shellcheck disable=SC1091
    . /etc/os-release
    case "${ID:-}" in
        linuxmint) DISTRO=mint ;;
        parrot)    DISTRO=parrot ;;
        *)
            if [[ " ${ID_LIKE:-} " == *" debian "* || " ${ID_LIKE:-} " == *" ubuntu "* ]]; then
                DISTRO=other
                warn "untested distro '${ID:-?}'; continuing with Debian defaults."
            else
                die "unsupported distro '${ID:-?}' (expected Linux Mint or Parrot OS)."
            fi
            ;;
    esac
    [[ "$(uname -m)" == x86_64 ]] || die "only x86_64 is supported (Neovim tarball, etc)."
    log "Detected ${PRETTY_NAME:-$ID} ($DISTRO); mode: $( ((UPGRADE)) && echo 'install + upgrade' || echo 'install missing only')"

    sudo -v   # prompt for the password once, up front
    mkdir -p "$CACHE_DIR"
}

system_update() {
    log "Refreshing package lists"
    apt_get update >/dev/null   # needed so availability checks are accurate
    ((UPGRADE)) || return 0
    # Parrot is a rolling release; its docs call for full-upgrade.
    local cmd=upgrade n
    [[ $DISTRO == parrot ]] && cmd=full-upgrade
    n="$(apt-get -s "$cmd" 2>/dev/null | grep -c '^Inst ' || true)"
    if ((n > 0)); then
        log "Upgrading $n system packages ($cmd)"
        apt_get "$cmd"
        changed "upgraded $n system packages"
    else
        info "System packages are up to date."
    fi
}

install_packages() {
    log "Installing packages"
    local pkgs=("${COMMON_PACKAGES[@]}")
    if [[ $DISTRO == parrot ]]; then
        pkgs+=("${PARROT_ONLY_PACKAGES[@]}")
    else
        info "Skipping pentest tools on $DISTRO: ${PARROT_ONLY_PACKAGES[*]}"
    fi
    apt_install_missing "${pkgs[@]}"

    local pkg app
    for pkg in "${!APT_OR_FLATPAK[@]}"; do
        app="${APT_OR_FLATPAK[$pkg]}"
        if dpkg_installed "$pkg"; then
            info "$pkg already installed (apt)."
        elif flatpak info "$app" >/dev/null 2>&1; then
            info "$app already installed (Flatpak)."
        elif apt_has "$pkg"; then
            apt_get install "$pkg"
            changed "apt installed: $pkg"
        else
            info "$pkg not in apt repos; using Flathub."
            ensure_flathub
            sudo flatpak install -y --noninteractive flathub "$app"
            changed "flatpak installed: $app"
        fi
    done

    # Signal Desktop refuses to run once too old, so keep Flatpak apps current too.
    if ((UPGRADE)) && command -v flatpak >/dev/null; then
        local n
        n="$(flatpak remote-ls --updates --columns=application 2>/dev/null | grep -c . || true)"
        if ((n > 0)); then
            sudo flatpak update -y --noninteractive
            changed "updated $n Flatpak refs"
        fi
    fi
}

install_rust_and_zellij() {
    log "Rust and zellij"
    if ! command -v rustup >/dev/null && [[ ! -x "$HOME/.cargo/bin/rustup" ]]; then
        curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y
        changed "installed rustup"
    else
        info "rustup already installed."
    fi
    # Rustup generates this file in the invoking user's home directory.
    # shellcheck disable=SC1091
    . "$HOME/.cargo/env"
    if ((UPGRADE)); then rustup update; fi

    if command -v zellij >/dev/null; then
        info "zellij already installed."
    else
        cargo install --locked zellij
        changed "installed zellij"
    fi
}

install_neovim() {
    log "Neovim (latest release tarball)"
    if dpkg_installed neovim; then
        info "Removing distro neovim package in favour of the release tarball."
        apt_get remove neovim
        changed "removed apt neovim"
    fi
    local dest=/opt/nvim-linux-x86_64 archive="$CACHE_DIR/nvim-linux-x86_64.tar.gz"
    if [[ -x "$dest/bin/nvim" ]] && ((!UPGRADE)); then
        info "$("$dest/bin/nvim" --version | head -n1) already installed."
        return
    fi

    fetch "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz" "$archive"
    tar -tzf "$archive" >/dev/null || die "corrupt Neovim archive: $archive (delete it and re-run)"
    local sum
    sum="$(sha256sum "$archive" | cut -d' ' -f1)"
    if [[ -x "$dest/bin/nvim" && "$(cat "$dest/.archive-sha256" 2>/dev/null)" == "$sum" ]]; then
        info "$("$dest/bin/nvim" --version | head -n1) is the latest release."
        return
    fi

    # Extract next to the target, then swap, so a failure never leaves /opt empty.
    local staging
    staging="$(sudo mktemp -d /opt/.nvim-staging.XXXXXX)"
    sudo tar -C "$staging" -xzf "$archive"
    sudo rm -rf /opt/nvim /opt/nvim-linux-x86_64   # /opt/nvim: layout from older script versions
    echo "$sum" | sudo tee "$staging/nvim-linux-x86_64/.archive-sha256" >/dev/null
    sudo mv "$staging/nvim-linux-x86_64" "$dest"
    sudo rmdir "$staging"
    changed "installed $("$dest/bin/nvim" --version | head -n1)"
}

install_lazyvim() {
    log "LazyVim"
    if [[ -f "$HOME/.config/nvim/lazy-lock.json" || -f "$HOME/.config/nvim/lua/config/lazy.lua" ]]; then
        info "LazyVim config already present; leaving it alone."
        return
    fi
    local d
    for d in "$HOME/.config/nvim" "$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.cache/nvim"; do
        if [[ -e "$d" ]]; then
            mv "$d" "$d.bak.$STAMP"
            info "Backed up $d -> $d.bak.$STAMP"
        fi
    done
    git clone --depth 1 https://github.com/LazyVim/starter "$HOME/.config/nvim"
    rm -rf "$HOME/.config/nvim/.git"
    changed "installed LazyVim starter config"
}

install_nerd_font() {
    log "JetBrainsMono Nerd Font"
    local name=JetBrainsMono
    local font_dir="$HOME/.local/share/fonts/$name"
    if [[ -d "$font_dir" && -n "$(ls -A "$font_dir")" ]] || [[ -d "$HOME/.fonts/$name" ]]; then
        info "$name already installed."
        return
    fi
    local zip="$CACHE_DIR/$name.zip"
    fetch "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$name.zip" "$zip"
    mkdir -p "$font_dir"
    unzip -oq "$zip" -d "$font_dir"
    fc-cache -f "$font_dir" >/dev/null
    changed "installed $name Nerd Font"
}

install_keyd() {
    log "keyd $KEYD_VERSION"
    local installed=""
    command -v keyd >/dev/null && installed="$(keyd --version 2>/dev/null | awk '{print $2}')"
    if [[ "$installed" == "$KEYD_VERSION" ]]; then
        info "keyd $KEYD_VERSION already installed."
    else
        info "Building keyd $KEYD_VERSION (found: ${installed:-none})."
        local src="$CACHE_DIR/keyd-$KEYD_VERSION"
        [[ -d "$src" ]] || git clone --depth 1 --branch "$KEYD_VERSION" https://github.com/rvaiya/keyd "$src"
        make -C "$src"
        sudo make -C "$src" install
        changed "installed keyd $KEYD_VERSION"
    fi
    if ! systemctl is-enabled --quiet keyd || ! systemctl is-active --quiet keyd; then
        sudo systemctl enable --now keyd
        changed "enabled keyd service"
    fi

    local config src dest reload=0
    for config in default.conf trackman.conf; do
        src="$(repo_file "etc/keyd/$config")"
        dest="/etc/keyd/$config"
        if install_root_file "$src" "$dest"; then
            changed "updated $dest"
            reload=1
        fi
    done
    if ((reload)); then
        sudo keyd reload || sudo systemctl restart keyd
    fi
}

configure_xfce_tiling() {
    local desktop="${XDG_CURRENT_DESKTOP:-}"
    if [[ "${desktop^^}" != *XFCE* ]] || ! command -v xfconf-query >/dev/null; then
        return 0
    fi

    log "Xfce window tiling shortcuts"
    local channel=xfce4-keyboard-shortcuts direction property action
    for direction in Left Right Up Down; do
        property="/xfwm4/custom/<Super>$direction"
        action="tile_${direction,,}_key"
        if [[ "$(xfconf-query --channel "$channel" --property "$property" 2>/dev/null)" != "$action" ]]; then
            xfconf-query --channel "$channel" --property "$property" --create --type string --set "$action"
            changed "set Xfce Super+$direction to $action"
        fi
    done
}

install_button_scroll() {
    log "Middle-button scrolling (libinput, X11)"
    # Hold middle + move = scroll; click without moving = normal middle click.
    if install_root_file "$(repo_file etc/X11/xorg.conf.d/40-button-scroll.conf)" \
        /etc/X11/xorg.conf.d/40-button-scroll.conf; then
        changed "installed /etc/X11/xorg.conf.d/40-button-scroll.conf"
    fi
    # Apply to the running X session too, so no re-login is needed.
    if [[ "${XDG_SESSION_TYPE:-}" == x11 ]] && command -v xinput >/dev/null; then
        local id
        while read -r id; do
            xinput set-prop "$id" "libinput Scroll Method Enabled" 0 0 1 2>/dev/null || true
        done < <(xinput list --id-only 2>/dev/null)
    elif [[ "${XDG_SESSION_TYPE:-}" == wayland ]]; then
        warn "Wayland session: xorg.conf.d does not apply; enable button scrolling in your desktop's mouse settings."
    fi
}

add_user_groups() {
    log "User groups for virtualization"
    local g groups_changed=0
    for g in libvirt kvm; do
        if ! getent group "$g" >/dev/null; then
            warn "group '$g' does not exist; skipped."
        elif id -nG "$USER" | tr ' ' '\n' | grep -qxF "$g"; then
            info "$USER already in $g."
        else
            sudo usermod -aG "$g" "$USER"
            changed "added $USER to group $g"
            groups_changed=1
        fi
    done
    ((groups_changed)) && warn "log out and back in for group changes to take effect."
    return 0
}

configure_shell() {
    log "Shell aliases (~/.bash_aliases)"
    local f="$HOME/.bash_aliases"
    # Expand PATH when .bash_aliases is sourced.
    # shellcheck disable=SC2016
    append_once "$f" "# Neovim Path" 'export PATH="$PATH:/opt/nvim-linux-x86_64/bin"'
    # Expand HOME when .bash_aliases is sourced.
    # shellcheck disable=SC2016
    append_once "$f" "# Cargo Environment" '. "$HOME/.cargo/env"'
    append_once "$f" "# Neovim Aliases" $'alias vi=\'nvim\'\nalias vim=\'nvim\''
    # Run the zellij command when .bash_aliases is sourced.
    # shellcheck disable=SC2016
    append_once "$f" "# Zellij Auto-Start" 'eval "$(zellij setup --generate-auto-start bash)"'
    # Mint's and Parrot's default ~/.bashrc source ~/.bash_aliases; warn if this one doesn't.
    grep -q 'bash_aliases' "$HOME/.bashrc" 2>/dev/null \
        || warn "~/.bashrc does not source ~/.bash_aliases; add: [ -f ~/.bash_aliases ] && . ~/.bash_aliases"
}

cleanup() {
    ((UPGRADE)) || return 0
    log "Cleanup"
    apt_get autoremove
    apt_get clean
}

summary() {
    log "Bootstrap complete."
    if ((${#CHANGES[@]})); then
        info "Changes made this run:"
        printf '      - %s\n' "${CHANGES[@]}"
        info "Open a new terminal (or log out/in) to pick up PATH, aliases and groups."
    else
        info "Nothing to do; everything was already set up."
    fi
}

main() {
    preflight "$@"
    system_update
    install_packages
    install_rust_and_zellij
    install_neovim
    install_lazyvim
    install_nerd_font
    install_keyd
    configure_xfce_tiling
    install_button_scroll
    add_user_groups
    configure_shell
    cleanup
    summary
}

# Allow sourcing for testing without running anything.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
