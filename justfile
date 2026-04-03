# rig — declare your dev tools in a justfile
# One command to install anything. `just --list` to browse.
# `just --choose` for an interactive fzf installer.

# Show help when invoked with no arguments
[private]
default:
    @echo "rig — declare your dev tools in a justfile\n"
    @echo "usage:"
    @echo "  just <tool>        install a single tool      (e.g. just ripgrep)"
    @echo "  just <group>       install a group             (e.g. just cli)"
    @echo "  just all           install everything"
    @echo "  just doctor        check what's installed"
    @echo "  just clean         purge package manager caches"
    @echo "  just --list        list all available recipes"
    @echo "  just --choose      interactive fzf installer"

import 'dev/cli.just'
import 'dev/python.just'
import 'dev/node.just'
import 'dev/go.just'
import 'dev/rust.just'
import 'dev/lsp.just'
import 'desktop/apps.just'

# ── OS detection ─────────────────────────────────────────

host_os  := os()
host_arch := arch()

# Linux distro ID from /etc/os-release (empty on non-Linux)
distro := `if [ -f /etc/os-release ]; then . /etc/os-release && echo "$ID"; fi`

# System package manager install command
sys_install := if host_os == "macos" {
    "brew install"
} else if distro =~ "(ubuntu|debian|pop|mint|elementary)" {
    "sudo apt-get install -y"
} else if distro =~ "(fedora)" {
    "sudo dnf install -y"
} else if distro =~ "(centos|rhel|rocky|alma)" {
    "sudo yum install -y"
} else if distro =~ "(arch|manjaro|endeavouros)" {
    "sudo pacman -S --noconfirm"
} else if distro =~ "(opensuse|suse)" {
    "sudo zypper install -y"
} else {
    error("unsupported OS/distro for system packages: " + host_os + "/" + distro)
}

# npm: no sudo needed on macOS (brew node writes to user-owned prefix)
npm_install := if host_os == "macos" { "npm i -g" } else { "sudo npm i -g" }

# ── Group targets ────────────────────────────────────────

# Install all CLI tools
cli: ripgrep jq bat fzf htop tmux eza zoxide fd fish awscli starship neovim fisher docker kubectl gh terraform helm op claude-code

# Install all Python tools
python: uv ruff black isort pyright pytest

# Install all Node tools
node: prettier eslint

# Install all Go tools
go-tools: gopls golangci-lint

# Install all Rust tools
rust-tools: cargo-edit cargo-watch

# Install all LSP servers
lsp: bash-language-server typescript-language-server lua-language-server

# ── Meta targets ─────────────────────────────────────────

# Install all dev tools
dev: cli python node go-tools rust-tools lsp

# Install everything (dev + desktop) with summary report
[script('bash')]
all:
    set -uo pipefail

    tools=(
        # cli
        ripgrep jq bat fzf htop tmux fd eza zoxide fish awscli starship
        neovim fisher docker kubectl gh terraform helm op claude-code
        # python
        uv ruff black isort pyright pytest
        # node
        prettier eslint
        # go
        gopls golangci-lint
        # rust
        cargo-edit cargo-watch
        # lsp
        bash-language-server typescript-language-server lua-language-server
        # desktop
        kitty ghostty zed jetbrains-mono-nerd-font
    )

    declare -a results=()
    declare -a messages=()
    errors=0
    warnings=0
    ok=0

    total=${#tools[@]}

    for i in "${!tools[@]}"; do
        tool="${tools[$i]}"
        n=$((i + 1))
        printf "  [%d/%d] %-30s " "$n" "$total" "$tool"
        output=$(just "$tool" 2>&1) && rc=0 || rc=$?
        if [[ $rc -eq 0 ]]; then
            results+=("ok")
            messages+=("")
            ((ok++))
            printf "\033[32mok\033[0m\n"
        else
            results+=("error")
            msg=$(echo "$output" | grep -v '^$' | tail -1)
            messages+=("$msg")
            ((errors++))
            printf "\033[31mfail\033[0m\n"
        fi
    done

    # ── Summary ──────────────────────────────────────────
    printf "\n"
    printf "  ══════════════════════════════════════════════════════════════════\n"
    printf "  rig install complete\n"
    printf "  ══════════════════════════════════════════════════════════════════\n\n"

    printf "  %-30s %-8s %s\n" "TOOL" "STATUS" "MESSAGE"
    printf "  %-30s %-8s %s\n" "----" "------" "-------"

    for i in "${!tools[@]}"; do
        tool="${tools[$i]}"
        status="${results[$i]}"
        msg="${messages[$i]}"
        if [[ "$status" == "ok" ]]; then
            printf "  %-30s \033[32m%-8s\033[0m\n" "$tool" "OK"
        else
            printf "  %-30s \033[31m%-8s\033[0m %s\n" "$tool" "FAIL" "$msg"
        fi
    done

    printf "\n  %s ok, %s failed\n\n" "$ok" "$errors"

    if [[ "$errors" -gt 0 ]]; then
        exit 1
    fi

# ── Diagnostics ──────────────────────────────────────────

# Check which declared tools are installed and which are missing
[script('bash')]
doctor:
    set -eo pipefail

    # recipe:binary — only listed where they differ
    resolve() {
        case "$1" in
            ripgrep)      echo rg ;;
            neovim)       echo nvim ;;
            awscli)       echo aws ;;
            claude-code)  echo claude ;;
            cargo-edit)   echo cargo-add ;;
            *)            echo "$1" ;;
        esac
    }

    # Tools that need special checks
    check_special() {
        case "$1" in
            fisher)
                fish -c "type fisher" &>/dev/null 2>&1 ;;
            jetbrains-mono-nerd-font)
                if [[ "{{ host_os }}" == "macos" ]]; then
                    brew list --cask font-jetbrains-mono-nerd-font &>/dev/null 2>&1
                else
                    fc-list 2>/dev/null | grep -qi "JetBrainsMono.*Nerd"
                fi ;;
            *) return 2 ;;
        esac
    }

    tools=(
        ripgrep jq bat fzf htop tmux fd eza zoxide fish awscli starship
        neovim fisher docker kubectl gh terraform helm op claude-code
        uv ruff black isort pyright pytest
        prettier eslint
        gopls golangci-lint
        cargo-edit cargo-watch
        bash-language-server typescript-language-server lua-language-server
        kitty ghostty zed jetbrains-mono-nerd-font
    )

    missing=0
    found=0

    printf "\n  %-30s %s\n" "TOOL" "STATUS"
    printf "  %-30s %s\n" "----" "------"

    for tool in "${tools[@]}"; do
        check_special "$tool" && rc=0 || rc=$?

        if [[ $rc -eq 2 ]]; then
            # Not special — resolve binary name and check PATH
            cmd="$(resolve "$tool")"
            if command -v "$cmd" &>/dev/null; then rc=0; else rc=1; fi
        fi

        if [[ $rc -eq 0 ]]; then
            printf "  %-30s \033[32m✓\033[0m\n" "$tool"
            ((found++))
        else
            printf "  %-30s \033[31m✗\033[0m\n" "$tool"
            ((missing++))
        fi
    done

    printf "\n  %s installed, %s missing\n\n" "$found" "$missing"

    if [[ "$missing" -gt 0 ]]; then
        exit 1
    fi

# ── Cleanup ──────────────────────────────────────────────

# Purge all package manager caches
[confirm("This will clean all package manager caches. Continue?")]
[script('bash')]
clean:
    set -euo pipefail
    echo "cleaning package manager caches..."

    # System package manager
    if [[ "{{ host_os }}" == "macos" ]]; then
        brew cleanup 2>/dev/null || true
    elif command -v apt-get &>/dev/null; then
        sudo apt-get clean && sudo apt-get autoremove -y
    elif command -v dnf &>/dev/null; then
        sudo dnf clean all
    elif command -v yum &>/dev/null; then
        sudo yum clean all
    elif command -v pacman &>/dev/null; then
        sudo pacman -Scc --noconfirm
    elif command -v zypper &>/dev/null; then
        sudo zypper clean --all
    fi

    # Language-specific managers
    cargo cache -a 2>/dev/null || true
    uv cache clean 2>/dev/null || true
    npm cache clean --force 2>/dev/null || true
    go clean -cache 2>/dev/null || true

    echo "done."
