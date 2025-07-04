#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting bootstrap process..."

# --- Setup Cache Directory ---
CACHE_DIR="$HOME/cache_bootstrap"
echo "Ensuring cache directory exists: $CACHE_DIR"
mkdir -p "$CACHE_DIR"

# --- System Updates ---
echo "Updating package lists..."
sudo apt update

echo "Upgrading installed packages..."
sudo apt upgrade -y

# --- Application Installation ---
echo "Installing common applications..."

# Install multiple packages with a single apt install command for efficiency
# Includes tools for virtualization, security, development, and general use
# 'build-essential' is crucial here for compiling applications like keyd later.
sudo apt install -y \
    zbar-tools \
    cinnamon \
    alacritty \
    signal-desktop \
    git \
    curl \
    tar \
    gzip \
    unzip \
    build-essential \
    burpsuite \
    zaproxy \
    qemu-kvm \
    libvirt-daemon-system \
    libvirt-clients \
    bridge-utils \
    virt-manager \
    qemu-guest-agent \
    spice-vdagent \
    timeshift

# --- Rust and Cargo Installation ---
echo "Installing Rust and Cargo..."
# Check if rustup is already installed to prevent re-running
if ! command -v rustup &> /dev/null; then
    curl https://sh.rustup.rs -sSf | sh -s -- -y # -y for non-interactive installation
    # Source cargo env immediately for subsequent commands in this script
    source "$HOME/.cargo/env"
else
    echo "Rust (rustup) is already installed. Skipping."
    # Ensure cargo env is sourced in current shell session if rustup was already there
    source "$HOME/.cargo/env"
fi

# Install zellij via cargo
echo "Installing zellij via cargo..."
if ! command -v zellij &> /dev/null; then
    cargo install --locked zellij
else
    echo "zellij is already installed. Skipping cargo install."
fi

# --- Neovim Installation ---
echo "Installing the latest version of Neovim..."

# Remove any existing apt-installed Neovim
echo "Removing any apt-installed Neovim..."
sudo apt remove -y nvim || true # '|| true' prevents script from exiting if nvim isn't installed

# Download the latest Neovim pre-built archive to cache
NVIM_ARCHIVE="$CACHE_DIR/nvim-linux-x86_64.tar.gz"
echo "Downloading the latest Neovim archive to $NVIM_ARCHIVE..."
if [ ! -f "$NVIM_ARCHIVE" ]; then # Only download if not already in cache
    curl -o "$NVIM_ARCHIVE" -L "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
else
    echo "Neovim archive already exists in cache. Skipping download."
fi

# Remove any previous manual Neovim installation directory
echo "Cleaning up previous Neovim installation directory in /opt..."
sudo rm -rf /opt/nvim

# Extract the new Neovim archive to /opt
echo "Extracting Neovim from "$NVIM_ARCHIVE" to /opt..."
sudo tar -C /opt -xzf "$NVIM_ARCHIVE"

# --- LazyVim Installation ---
echo "Installing LazyVim configuration for Neovim..."

# Check if LazyVim appears to be already installed based on a key file
if [ -f "$HOME/.config/nvim/lua/lazyvim/config/init.lua" ]; then
    echo "LazyVim appears to be already installed. Skipping re-installation."
else
    echo "Proceeding with LazyVim installation."

    # Backup existing Neovim configs
    echo "Backing up existing Neovim configuration files..."
    mv ~/.config/nvim{,.bak} 2>/dev/null || true # Ignore errors if file doesn't exist
    mv ~/.local/share/nvim{,.bak} 2>/dev/null || true
    mv ~/.local/state/nvim{,.bak} 2>/dev/null || true
    mv ~/.cache/nvim{,.bak} 2>/dev/null || true

    # Ensure the target directory for new config is clean and writable by user
    echo "Ensuring ~/.config/nvim is clean for new configuration (forceful removal)..."
    # Use sudo rm -rf to ensure full cleanup of potentially problematic files/directories
    sudo rm -rf "$HOME/.config/nvim"

    # Clone LazyVim starter to cache, then copy
    LAZYVIM_REPO_DIR="$CACHE_DIR/LazyVim_starter"
    echo "Cloning LazyVim starter configuration to $LAZYVIM_REPO_DIR..."
    if [ ! -d "$LAZYVIM_REPO_DIR" ]; then
        git clone https://github.com/LazyVim/starter "$LAZYVIM_REPO_DIR"
    else
        echo "LazyVim starter already exists in cache. Pulling latest changes..."
        (cd "$LAZYVIM_REPO_DIR" && git pull)
    fi

    echo "Copying LazyVim configuration from cache to ~/.config/nvim..."
    # Create target directory with correct permissions for the current user
    mkdir -p "$HOME/.config/nvim"
    # Copy contents using -a to preserve permissions/ownership from the cloned repo
    # and ensure all files including dotfiles are copied correctly.
    cp -a "$LAZYVIM_REPO_DIR/." "$HOME/.config/nvim/"

    # Remove the .git folder from copied LazyVim clone
    echo "Removing .git folder from copied LazyVim configuration..."
    rm -rf "$HOME/.config/nvim/.git"
fi

# --- Nerd Fonts Installation (JetBrainsMono) ---
echo "Installing JetBrainsMono Nerd Font..."

FONT_NAME="JetBrainsMono"
FONT_DIR="$HOME/.fonts/$FONT_NAME"
FONT_ZIP="$CACHE_DIR/$FONT_NAME.zip" # Download to cache

# Check if the font directory already exists and contains files
if [ -d "$FONT_DIR" ] && [ "$(ls -A "$FONT_DIR")" ]; then
    echo "$FONT_NAME Nerd Font appears to be already installed. Skipping."
else
    echo "Downloading $FONT_NAME Nerd Font to $FONT_ZIP..."
    if [ ! -f "$FONT_ZIP" ]; then # Only download if not already in cache
        curl -o "$FONT_ZIP" -L "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$FONT_NAME.zip"
    else
        echo "Font archive already exists in cache. Skipping download."
    fi

    echo "Creating fonts directory: ${HOME}/.fonts"
    mkdir -p "$HOME/.fonts"

    echo "Unzipping "$FONT_ZIP" to "$FONT_DIR/"..."
    unzip -o "$FONT_ZIP" -d "$FONT_DIR/" # -o option to overwrite files without prompt

    echo "Updating font cache..."
    fc-cache -fv
    echo "$FONT_NAME Nerd Font installation complete."
fi

# --- Keyd Installation ---
echo "Installing keyd..."
KEYD_REPO_DIR="$CACHE_DIR/keyd"

if ! command -v keyd &> /dev/null || ! systemctl is-active --quiet keyd; then
    echo "Cloning keyd repository to $KEYD_REPO_DIR..."
    if [ ! -d "$KEYD_REPO_DIR" ]; then
        git clone https://github.com/rvaiya/keyd "$KEYD_REPO_DIR"
    else
        echo "Keyd repository already exists in cache. Pulling latest changes..."
        (cd "$KEYD_REPO_DIR" && git pull)
    fi

    echo "Building and installing keyd..."
    (cd "$KEYD_REPO_DIR" && make && sudo make install)

    echo "Enabling and starting keyd service..."
    sudo systemctl enable --now keyd
else
    echo "keyd is already installed and running. Skipping build and install."
fi

# Configure keyd default.conf
KEYD_CONF_DIR="/etc/keyd"
KEYD_DEFAULT_CONF="$KEYD_CONF_DIR/default.conf"
MY_KEYD_CONF_URL="https://raw.githubusercontent.com/sunzenshen/setup/master/etc/keyd/default.conf"
MY_KEYD_CONF_CACHE="$CACHE_DIR/keyd_default.conf"

echo "Configuring keyd/default.conf..."

# Download my specific keyd default.conf to cache
echo "Downloading custom keyd config to $MY_KEYD_CONF_CACHE..."
if [ ! -f "$MY_KEYD_CONF_CACHE" ]; then
    curl -o "$MY_KEYD_CONF_CACHE" -L "$MY_KEYD_CONF_URL"
else
    echo "Custom keyd config already exists in cache. Skipping download."
fi

# Check if the content is different before copying and restarting service
if sudo diff -q "$MY_KEYD_CONF_CACHE" "$KEYD_DEFAULT_CONF" &>/dev/null; then
    echo "Keyd default.conf is already up-to-date. Skipping copy and restart."
else
    echo "Backing up existing /etc/keyd/default.conf (if any)..."
    sudo mv "$KEYD_DEFAULT_CONF"{,.bak} 2>/dev/null || true # Backup existing
    echo "Copying custom keyd config to $KEYD_DEFAULT_CONF..."
    sudo mkdir -p "$KEYD_CONF_DIR" # Ensure directory exists
    sudo cp "$MY_KEYD_CONF_CACHE" "$KEYD_DEFAULT_CONF"

    echo "Reloading keyd service to apply new configuration..."
    sudo systemctl reload keyd || sudo systemctl restart keyd # reload if possible, else restart
fi

# --- Add User to libvirt and kvm groups ---
echo "Adding current user ($USER) to 'libvirt' and 'kvm' groups..."
# Check if user is already in libvirt group
if ! id -Gn "$USER" | grep -q '\blibvirt\b'; then
    sudo adduser "$USER" libvirt
    echo "User '$USER' added to 'libvirt' group."
else
    echo "User '$USER' is already in 'libvirt' group. Skipping."
fi

# Check if user is already in kvm group
if ! id -Gn "$USER" | grep -q '\bkvm\b'; then
    sudo adduser "$USER" kvm
    echo "User '$USER' added to 'kvm' group."
else
    echo "User '$USER' is already in 'kvm' group. Skipping."
fi
echo "Note: You will need to log out and log back in for group changes to take effect."


# --- .bash_aliases Configuration ---
echo "Configuring ~/.bash_aliases for Neovim and Zellij..."
BASH_ALIASES_FILE="$HOME/.bash_aliases"
NEOVIM_BIN_PATH="/opt/nvim-linux-x86_64/bin"

# Ensure .bash_aliases file exists
touch "$BASH_ALIASES_FILE"

# The .bashrc already sources ~/.bash_aliases, so no need to add that block.
# We only add the specific configurations to ~/.bash_aliases.

# Add Neovim to PATH if not already present in .bash_aliases
if ! grep -q "export PATH=\"\$PATH:$NEOVIM_BIN_PATH\"" "$BASH_ALIASES_FILE"; then
    echo "Adding Neovim to PATH in $BASH_ALIASES_FILE..."
    echo "" >> "$BASH_ALIASES_FILE" # Add a newline for separation
    echo "# Neovim Path" >> "$BASH_ALIASES_FILE"
    echo "export PATH=\"\$PATH:$NEOVIM_BIN_PATH\"" >> "$BASH_ALIASES_FILE"
else
    echo "Neovim PATH already configured in $BASH_ALIASES_FILE."
fi

# Add .cargo/env source if not already present in .bash_aliases
if ! grep -q ". \"\$HOME/.cargo/env\"" "$BASH_ALIASES_FILE"; then
    echo "Adding .cargo/env source to $BASH_ALIASES_FILE..."
    echo "" >> "$BASH_ALIASES_FILE"
    echo "# Cargo Environment" >> "$BASH_ALIASES_FILE"
    echo ". \"\$HOME/.cargo/env\"" >> "$BASH_ALIASES_FILE"
else
    echo ".cargo/env already sourced in $BASH_ALIASES_FILE."
fi

# Add Neovim aliases if not already present in .bash_aliases
if ! grep -q "alias vi='nvim'" "$BASH_ALIASES_FILE"; then
    echo "Adding 'alias vi=nvim' to $BASH_ALIASES_FILE..."
    echo "" >> "$BASH_ALIASES_FILE"
    echo "# Neovim Aliases" >> "$BASH_ALIASES_FILE"
    echo "alias vi='nvim'" >> "$BASH_ALIASES_FILE"
else
    echo "'alias vi=nvim' already configured in $BASH_ALIASES_FILE."
fi

if ! grep -q "alias vim='nvim'" "$BASH_ALIASES_FILE"; then
    echo "Adding 'alias vim=nvim' to $BASH_ALIASES_FILE..."
    echo "alias vim='nvim'" >> "$BASH_ALIASES_FILE"
else
    echo "'alias vim=nvim' already configured in $BASH_ALIASES_FILE."
fi

# Add zellij auto-start if not already present in .bash_aliases
if ! grep -q "zellij setup --generate-auto-start bash" "$BASH_ALIASES_FILE"; then
    echo "Adding zellij auto-start to $BASH_ALIASES_FILE..."
    echo "" >> "$BASH_ALIASES_FILE"
    echo "# Zellij Auto-Start" >> "$BASH_ALIASES_FILE"
    echo "eval \"\$(zellij setup --generate-auto-start bash)\"" >> "$BASH_ALIASES_FILE"
else
    echo "Zellij auto-start already configured in $BASH_ALIASES_FILE."
fi


# --- System Cleanup ---
echo "Cleaning up unnecessary packages and cache..."
sudo apt autoremove -y
sudo apt clean -y

echo "Bootstrap process completed successfully!"

# --- Source .bashrc ---
echo "Sourcing ~/.bashrc to apply changes immediately..."
source "$HOME/.bashrc"

echo "All changes should now be active in this terminal session."
echo "IMPORTANT: For virtualization group changes to take effect, you must log out and log back in."