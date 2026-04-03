#!/usr/bin/env bash
set -euo pipefail

# Bootstrap script — installs `just` if not already present,
# then hands off to the justfile.

if command -v just &>/dev/null; then
    echo "just is already installed: $(just --version)"
    exit 0
fi

echo "just not found — installing..."

case "$(uname -s)" in
    Darwin)
        if ! command -v brew &>/dev/null; then
            echo "brew not found — installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install just
        ;;
    Linux)
        # Prefer the distro package manager if it has just
        if command -v apt-get &>/dev/null; then
            sudo apt-get update && sudo apt-get install -y just
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y just
        elif command -v pacman &>/dev/null; then
            sudo pacman -S --noconfirm just
        elif command -v zypper &>/dev/null; then
            sudo zypper install -y just
        else
            # Fallback: official prebuilt binary
            echo "no supported package manager found — installing from official binary..."
            curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh \
                | bash -s -- --to ~/.local/bin
            echo "installed to ~/.local/bin/just — make sure ~/.local/bin is in your PATH"
        fi
        ;;
    *)
        echo "error: unsupported OS — install just manually: https://github.com/casey/just#installation"
        exit 1
        ;;
esac

echo "done: $(just --version)"
