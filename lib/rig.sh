#!/usr/bin/env bash
# lib/rig.sh — shared helpers for rig
# All tool metadata lives in lib/tools.tsv — this file only has logic.

# Ensure common tool paths are available in non-interactive shells
export PATH="$HOME/go/bin:$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# ── Registry loader ──────────────────────────────────────

# Directory where this script lives
_rig_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parallel arrays populated from tools.tsv (loaded once)
_rig_tools=()
_rig_binaries=()
_rig_groups=()
_rig_methods=()
_rig_pkgs=()
_rig_depends=()
_rig_uninstalls=()
_rig_platforms=()
_rig_loaded=false

_rig_load() {
    if [[ "$_rig_loaded" == "true" ]]; then return; fi

    while IFS=$'\t' read -r tool binary group method pkg depends uninstall platforms; do
        # skip comments and blank lines
        [[ -z "$tool" || "$tool" == \#* ]] && continue
        _rig_tools+=("$tool")
        _rig_binaries+=("$([ "$binary" != "-" ] && echo "$binary" || echo "$tool")")
        _rig_groups+=("$group")
        _rig_methods+=("$method")
        _rig_pkgs+=("$([ "$pkg" != "-" ] && echo "$pkg" || echo "$tool")")
        _rig_depends+=("$([ "$depends" != "-" ] && echo "$depends")")
        _rig_uninstalls+=("$([ "$uninstall" != "-" ] && echo "$uninstall")")
        _rig_platforms+=("$([ -n "${platforms:-}" ] && [ "$platforms" != "-" ] && echo "$platforms")")
    done < "$_rig_dir/tools.tsv"

    _rig_loaded=true
}

# Current platform string: "macos" or "linux"
_rig_current_platform() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        echo "macos"
    else
        echo "linux"
    fi
}

# Current arch string: "x86_64" or "aarch64"
_rig_current_arch() {
    uname -m
}

# Find index of a tool (sets _idx, returns 1 if not found)
_rig_index() {
    _rig_load
    local i
    for i in "${!_rig_tools[@]}"; do
        if [[ "${_rig_tools[$i]}" == "$1" ]]; then
            _idx=$i
            return 0
        fi
    done
    return 1
}

# ── Public API ───────────────────────────────────────────

rig_all_tools() {
    _rig_load
    echo "${_rig_tools[@]}"
}

rig_resolve() {
    _rig_index "$1" || { echo "$1"; return; }
    echo "${_rig_binaries[$_idx]}"
}

rig_group() {
    _rig_index "$1" || { echo "unknown"; return; }
    echo "${_rig_groups[$_idx]}"
}

rig_install_method() {
    _rig_index "$1" || { echo "unknown"; return; }
    echo "${_rig_methods[$_idx]}"
}

rig_pkg() {
    _rig_index "$1" || { echo "$1"; return; }
    echo "${_rig_pkgs[$_idx]}"
}

rig_depends() {
    _rig_index "$1" || return
    echo "${_rig_depends[$_idx]}"
}

rig_platforms_of() {
    _rig_index "$1" || { echo ""; return; }
    echo "${_rig_platforms[$_idx]}"
}

# Return 0 if the tool is supported on the current platform/arch.
# Empty platforms field = supported everywhere.
# Supports simple OS tags ("macos", "linux") and arch-qualified tags
# ("linux-x86_64", "linux-aarch64") in the same comma-separated list.
rig_is_supported() {
    local plats
    plats=$(rig_platforms_of "$1")
    [[ -z "$plats" ]] && return 0
    local current arch qualified
    current=$(_rig_current_platform)
    arch=$(_rig_current_arch)
    qualified="${current}-${arch}"
    case ",$plats," in
        *",$current,"*)    return 0 ;;
        *",$qualified,"*)  return 0 ;;
        *) return 1 ;;
    esac
}

# Exit 0 with a skip message if the tool is macOS-only and we're not on macOS.
# Use inside a [script('bash')] recipe to self-skip cleanly.
rig_skip_if_unsupported() {
    local tool="${1:-this tool}"
    if ! rig_is_supported "$tool"; then
        local plats
        plats=$(rig_platforms_of "$tool")
        echo "  skipping ${tool}: only supported on ${plats}"
        exit 0
    fi
}

# ── Dependency-sorted tool list ──────────────────────────

# Topological sort: returns all tools supported on the current platform,
# ordered so dependencies come first. Uses Kahn's algorithm. Bash 3.2 compatible.
rig_sorted_tools() {
    _rig_load
    local count=${#_rig_tools[@]}

    # Build a "has been emitted" lookup string (space-separated)
    local emitted=" "
    local sorted=()
    local remaining=()

    # Start with all tool indices that are supported on the current platform
    local i
    for (( i = 0; i < count; i++ )); do
        rig_is_supported "${_rig_tools[$i]}" || continue
        remaining+=("$i")
    done

    while [[ ${#remaining[@]} -gt 0 ]]; do
        # Use a string to collect next-round indices (bash 3.2 safe)
        local next_remaining_str=""
        local progress=false

        for i in "${remaining[@]}"; do
            local deps="${_rig_depends[$i]}"
            if [[ -z "$deps" ]]; then
                # No dependencies — emit immediately
                sorted+=("${_rig_tools[$i]}")
                emitted="$emitted${_rig_tools[$i]} "
                progress=true
            else
                # Check if all deps have been emitted
                local all_met=true
                local saved_ifs="$IFS"
                IFS=','
                for dep in $deps; do
                    case "$emitted" in
                        *" $dep "*) ;;  # found
                        *) all_met=false; break ;;
                    esac
                done
                IFS="$saved_ifs"

                if [[ "$all_met" == "true" ]]; then
                    sorted+=("${_rig_tools[$i]}")
                    emitted="$emitted${_rig_tools[$i]} "
                    progress=true
                else
                    next_remaining_str="$next_remaining_str $i"
                fi
            fi
        done

        if [[ "$progress" != "true" ]]; then
            # Unresolvable deps (cycle or missing) — emit remainder as-is
            for i in $next_remaining_str; do
                sorted+=("${_rig_tools[$i]}")
            done
            break
        fi

        # Rebuild remaining array from string
        remaining=()
        for i in $next_remaining_str; do
            remaining+=("$i")
        done
    done

    echo "${sorted[@]}"
}

# ── Installation check ───────────────────────────────────

rig_is_installed() {
    local tool="$1"
    case "$tool" in
        fisher)
            fish -c "type fisher" &>/dev/null
            return $? ;;
        jetbrains-mono-nerd-font)
            if [[ "$(uname -s)" != "Darwin" ]]; then
                fc-list 2>/dev/null | grep -qi "JetBrainsMono.*Nerd"
                return $?
            fi ;;
    esac

    # Check PATH first
    local cmd
    cmd=$(rig_resolve "$tool")
    if [[ -n "$cmd" ]] && command -v "$cmd" &>/dev/null; then
        return 0
    fi

    # Cask apps may not have a CLI in PATH — check brew cask
    if [[ "$(uname -s)" == "Darwin" && "$(rig_install_method "$tool")" == "cask" ]]; then
        brew list --cask "$(rig_pkg "$tool")" &>/dev/null 2>&1
        return $?
    fi

    return 1
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
                brew list --cask --versions "$(rig_pkg "$tool")" 2>/dev/null \
                    | awk '{print $2}' || echo "installed"
            else
                echo "installed"
            fi ;;
        docker)
            docker --version 2>/dev/null | sed 's/Docker version //' | cut -d, -f1 ;;
        *)
            if [[ -z "$cmd" || "$cmd" == "$tool" ]] && ! command -v "$cmd" &>/dev/null; then
                echo "installed"
                return 0
            fi
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

# ── Uninstall command ────────────────────────────────────

rig_uninstall_cmd() {
    local tool="$1"
    local host_os="$2"

    # Check for a tool-specific uninstall command in the registry
    _rig_index "$tool" || { echo "# unknown tool: $tool"; return; }
    local custom_uninstall="${_rig_uninstalls[$_idx]}"
    if [[ -n "$custom_uninstall" ]]; then
        echo "$custom_uninstall"
        return
    fi

    # Generate uninstall command from method
    local method
    method=$(rig_install_method "$tool")
    local pkg
    pkg=$(rig_pkg "$tool")

    case "$method" in
        cargo)
            echo "cargo uninstall $pkg" ;;
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
                echo "brew uninstall --cask $pkg"
            else
                echo "# use your system package manager to remove $tool"
            fi ;;
        system)
            if [[ "$host_os" == "macos" ]]; then
                echo "brew uninstall $pkg"
            else
                echo "# use your system package manager to remove $tool"
            fi ;;
        *)
            echo "# manual uninstall required for $tool" ;;
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

# ── Linux package family detection + install helpers ────

# Detect the native package format: "deb", "rpm", or "other".
rig_pkg_family() {
    if command -v dpkg &>/dev/null && command -v apt-get &>/dev/null; then
        echo "deb"
    elif command -v rpm &>/dev/null \
        && { command -v dnf &>/dev/null || command -v yum &>/dev/null || command -v zypper &>/dev/null; }; then
        echo "rpm"
    else
        echo "other"
    fi
}

# Download (or copy) a .deb and install it via apt-get so deps resolve.
rig_install_deb() {
    local src="$1"
    local tmp file
    tmp="$(mktemp -d)"
    file="$tmp/pkg.deb"
    if [[ "$src" == http* ]]; then
        curl -fsSL -o "$file" "$src"
    else
        cp "$src" "$file"
    fi
    sudo apt-get install -y "$file"
    rm -rf "$tmp"
}

# Download (or copy) an .rpm and install it with whichever rpm frontend is present.
rig_install_rpm() {
    local src="$1"
    local tmp file
    tmp="$(mktemp -d)"
    file="$tmp/pkg.rpm"
    if [[ "$src" == http* ]]; then
        curl -fsSL -o "$file" "$src"
    else
        cp "$src" "$file"
    fi
    if command -v dnf &>/dev/null; then
        sudo dnf install -y "$file"
    elif command -v zypper &>/dev/null; then
        sudo zypper install -y --allow-unsigned-rpm "$file"
    elif command -v yum &>/dev/null; then
        sudo yum install -y "$file"
    else
        rm -rf "$tmp"
        return 1
    fi
    rm -rf "$tmp"
}

# Resolve a GitHub "latest release" asset URL matching a filename pattern.
# Usage: rig_gh_latest_asset <owner/repo> <pattern>
# Pattern is a POSIX-ERE fragment matched against the filename.
rig_gh_latest_asset() {
    local repo="$1" pattern="$2"
    curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" \
        | grep -oE '"browser_download_url":[[:space:]]*"[^"]+"' \
        | sed -E 's/.*"(https[^"]+)".*/\1/' \
        | grep -E "$pattern" \
        | head -1
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
