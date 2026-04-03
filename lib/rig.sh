#!/usr/bin/env bash
# lib/rig.sh — shared helpers for rig

# ── Tool list ────────────────────────────────────────────

rig_all_tools() {
    echo \
        ripgrep jq bat fzf htop tmux fd eza zoxide fish awscli starship \
        neovim fisher docker kubectl gh terraform helm op claude-code \
        uv ruff black isort pyright pytest \
        prettier eslint \
        gopls golangci-lint \
        cargo-edit cargo-watch \
        bash-language-server typescript-language-server lua-language-server \
        kitty ghostty zed jetbrains-mono-nerd-font
}

# ── Name resolution ──────────────────────────────────────

# Map recipe name to the binary/command name
rig_resolve() {
    case "$1" in
        ripgrep)                echo rg ;;
        neovim)                 echo nvim ;;
        awscli)                 echo aws ;;
        claude-code)            echo claude ;;
        cargo-edit)             echo cargo-add ;;
        jetbrains-mono-nerd-font) echo "" ;;
        fisher)                 echo "" ;;
        *)                      echo "$1" ;;
    esac
}

# ── Installation check ───────────────────────────────────

rig_is_installed() {
    local tool="$1"
    case "$tool" in
        fisher)
            fish -c "type fisher" &>/dev/null ;;
        jetbrains-mono-nerd-font)
            if [[ "$(uname -s)" == "Darwin" ]]; then
                brew list --cask font-jetbrains-mono-nerd-font &>/dev/null 2>&1
            else
                fc-list 2>/dev/null | grep -qi "JetBrainsMono.*Nerd"
            fi ;;
        *)
            local cmd
            cmd=$(rig_resolve "$tool")
            [[ -n "$cmd" ]] && command -v "$cmd" &>/dev/null ;;
    esac
}

# ── Version detection ────────────────────────────────────

rig_version() {
    local tool="$1"

    if ! rig_is_installed "$tool"; then
        echo "not installed"
        return 1
    fi

    local cmd
    cmd=$(rig_resolve "$tool")

    case "$tool" in
        fisher)
            fish -c "fisher --version 2>/dev/null" 2>/dev/null || echo "unknown" ;;
        jetbrains-mono-nerd-font)
            if [[ "$(uname -s)" == "Darwin" ]]; then
                brew list --cask --versions font-jetbrains-mono-nerd-font 2>/dev/null \
                    | awk '{print $2}' || echo "installed"
            else
                echo "installed"
            fi ;;
        docker)
            docker --version 2>/dev/null | sed 's/Docker version //' | cut -d, -f1 ;;
        *)
            if [[ -z "$cmd" ]]; then
                echo "installed"
                return 0
            fi
            # Try common version flags in order
            local ver
            ver=$("$cmd" --version 2>/dev/null | head -1) \
                || ver=$("$cmd" -V 2>/dev/null | head -1) \
                || ver=$("$cmd" version 2>/dev/null | head -1) \
                || ver="installed"
            echo "$ver"
            ;;
    esac
}

# ── Binary path ──────────────────────────────────────────

rig_which() {
    local tool="$1"
    case "$tool" in
        fisher)
            fish -c "which fisher" 2>/dev/null || echo "fish plugin" ;;
        jetbrains-mono-nerd-font)
            echo "font (no binary)" ;;
        *)
            local cmd
            cmd=$(rig_resolve "$tool")
            if [[ -n "$cmd" ]]; then
                command -v "$cmd" 2>/dev/null || echo "not found"
            else
                echo "not found"
            fi ;;
    esac
}

# ── Install method ───────────────────────────────────────

rig_install_method() {
    case "$1" in
        fd|eza|zoxide|cargo-edit|cargo-watch)
            echo "cargo" ;;
        gopls)
            echo "go" ;;
        ruff|black|isort|pyright|pytest)
            echo "uv" ;;
        prettier|eslint|bash-language-server|typescript-language-server)
            echo "npm" ;;
        uv|starship|fisher|claude-code|lua-language-server)
            echo "custom" ;;
        docker|kitty|ghostty|zed|op|jetbrains-mono-nerd-font)
            echo "cask" ;;
        golangci-lint|ripgrep|jq|bat|fzf|htop|tmux|fish|awscli|neovim|kubectl|gh|terraform|helm)
            echo "system" ;;
        *)
            echo "unknown" ;;
    esac
}

# ── Uninstall command ────────────────────────────────────

rig_uninstall_cmd() {
    local tool="$1"
    local host_os="$2"

    case "$(rig_install_method "$tool")" in
        cargo)
            case "$tool" in
                fd) echo "cargo uninstall fd-find" ;;
                *)  echo "cargo uninstall $tool" ;;
            esac ;;
        go)
            local cmd
            cmd=$(rig_resolve "$tool")
            echo "rm -f \"$(go env GOPATH 2>/dev/null || echo '$GOPATH')/bin/$cmd\"" ;;
        uv)
            echo "uv tool uninstall $tool" ;;
        npm)
            if [[ "$host_os" == "macos" ]]; then
                echo "npm uninstall -g $tool"
            else
                echo "sudo npm uninstall -g $tool"
            fi ;;
        cask)
            if [[ "$host_os" == "macos" ]]; then
                case "$tool" in
                    jetbrains-mono-nerd-font) echo "brew uninstall --cask font-jetbrains-mono-nerd-font" ;;
                    op)                       echo "brew uninstall --cask 1password-cli" ;;
                    *)                        echo "brew uninstall --cask $tool" ;;
                esac
            else
                echo "# use your system package manager to remove $tool"
            fi ;;
        system)
            if [[ "$host_os" == "macos" ]]; then
                echo "brew uninstall $tool"
            else
                echo "# use your system package manager to remove $tool"
            fi ;;
        custom)
            case "$tool" in
                uv)                   echo "rm -f ~/.local/bin/uv ~/.local/bin/uvx" ;;
                starship)             echo "rm -f \"$(command -v starship 2>/dev/null || echo /usr/local/bin/starship)\"" ;;
                fisher)               echo "fish -c 'fisher remove jorgebucaran/fisher'" ;;
                claude-code)          echo "npm uninstall -g @anthropic-ai/claude-code" ;;
                lua-language-server)  echo "rm -rf ~/.local/lib/lua-language-server ~/.local/bin/lua-language-server" ;;
                *)                    echo "# manual uninstall required for $tool" ;;
            esac ;;
        *)
            echo "# unknown install method for $tool" ;;
    esac
}

# ── Tool group ───────────────────────────────────────────

rig_group() {
    case "$1" in
        ripgrep|jq|bat|fzf|htop|tmux|fd|eza|zoxide|fish|awscli|starship|neovim|fisher|docker|kubectl|gh|terraform|helm|op|claude-code)
            echo "cli" ;;
        uv|ruff|black|isort|pyright|pytest)
            echo "python" ;;
        prettier|eslint)
            echo "node" ;;
        gopls|golangci-lint)
            echo "go" ;;
        cargo-edit|cargo-watch)
            echo "rust" ;;
        bash-language-server|typescript-language-server|lua-language-server)
            echo "lsp" ;;
        kitty|ghostty|zed|jetbrains-mono-nerd-font)
            echo "desktop" ;;
        *)
            echo "unknown" ;;
    esac
}

# ── Group → justfile mapping ─────────────────────────────

rig_group_file() {
    case "$1" in
        cli)     echo "dev/cli.just" ;;
        python)  echo "dev/python.just" ;;
        node)    echo "dev/node.just" ;;
        go)      echo "dev/go.just" ;;
        rust)    echo "dev/rust.just" ;;
        lsp)     echo "dev/lsp.just" ;;
        desktop) echo "desktop/apps.just" ;;
        *)       echo "" ;;
    esac
}

# ── Retry with exponential backoff ───────────────────────

rig_retry() {
    local max_attempts="${1:-3}"
    local delay=2
    shift

    local attempt=1
    local output rc

    while [[ $attempt -le $max_attempts ]]; do
        output=$("$@" 2>&1) && rc=0 || rc=$?
        if [[ $rc -eq 0 ]]; then
            echo "$output"
            return 0
        fi
        if [[ $attempt -lt $max_attempts ]]; then
            echo "  attempt $attempt/$max_attempts failed, retrying in ${delay}s..." >&2
            sleep "$delay"
            delay=$((delay * 2))
        fi
        ((attempt++))
    done

    echo "$output"
    return $rc
}

# ── Desktop notifications ────────────────────────────────

rig_notify() {
    local title="$1"
    local message="$2"

    case "$(uname -s)" in
        Darwin)
            osascript -e "display notification \"$message\" with title \"$title\"" 2>/dev/null || true ;;
        Linux)
            if command -v notify-send &>/dev/null; then
                notify-send "$title" "$message" 2>/dev/null || true
            fi ;;
    esac
}
