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
    @echo "  just all           install everything          (skips installed; force=true to override)"
    @echo "  just update        upgrade installed tools     (skips tools not yet installed)"
    @echo "  just info <tool>   show tool details           (version, path, install method)"
    @echo "  just outdated      check for available updates"
    @echo "  just uninstall <t> remove a tool"
    @echo "  just snapshot      save installed tools to ~/.rig/snapshot.txt"
    @echo "  just restore       reinstall tools from snapshot"
    @echo "  just add           add a new tool recipe interactively"
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

# Force reinstall even if already installed (just all force=true)
force := env("RIG_FORCE", "false")

# Path to shared helpers
rig_helpers := justfile_directory() / "lib" / "rig.sh"

# Max retry attempts for failed installs
max_retries := env("RIG_RETRIES", "3")

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
# Skips already-installed tools unless force=true
[script('bash')]
all:
    set -uo pipefail
    source "{{ rig_helpers }}"

    tools=($(rig_all_tools))
    force="{{ force }}"
    max_retries="{{ max_retries }}"

    declare -a results=()
    declare -a messages=()
    errors=0
    skipped=0
    ok=0
    total=${#tools[@]}
    start_time=$SECONDS

    for i in "${!tools[@]}"; do
        tool="${tools[$i]}"
        n=$((i + 1))
        printf "  [%d/%d] %-30s " "$n" "$total" "$tool"

        # Idempotent skip: if installed and not forced, skip
        if [[ "$force" != "true" ]] && rig_is_installed "$tool"; then
            results+=("skip")
            messages+=("")
            ((skipped++))
            printf "\033[33mskipped\033[0m (already installed)\n"
            continue
        fi

        # Retry with backoff
        attempt=1
        delay=2
        output=""
        rc=1
        while [[ $attempt -le $max_retries ]]; do
            output=$(just "$tool" 2>&1) && rc=0 || rc=$?
            if [[ $rc -eq 0 ]]; then
                break
            fi
            if [[ $attempt -lt $max_retries ]]; then
                printf "\033[33mretry %d/%d\033[0m " "$attempt" "$max_retries"
                sleep "$delay"
                delay=$((delay * 2))
            fi
            ((attempt++))
        done

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

    elapsed=$(( SECONDS - start_time ))
    mins=$(( elapsed / 60 ))
    secs=$(( elapsed % 60 ))

    # ── Summary ──────────────────────────────────────────
    printf "\n"
    printf "  ══════════════════════════════════════════════════════════════════\n"
    printf "  rig install complete  (%dm %ds)\n" "$mins" "$secs"
    printf "  ══════════════════════════════════════════════════════════════════\n\n"

    printf "  %-30s %-10s %s\n" "TOOL" "STATUS" "MESSAGE"
    printf "  %-30s %-10s %s\n" "----" "------" "-------"

    for i in "${!tools[@]}"; do
        tool="${tools[$i]}"
        status="${results[$i]}"
        msg="${messages[$i]}"
        case "$status" in
            ok)   printf "  %-30s \033[32m%-10s\033[0m\n"    "$tool" "OK" ;;
            skip) printf "  %-30s \033[33m%-10s\033[0m\n"    "$tool" "SKIPPED" ;;
            *)    printf "  %-30s \033[31m%-10s\033[0m %s\n" "$tool" "FAIL" "$msg" ;;
        esac
    done

    printf "\n  %s ok, %s skipped, %s failed\n\n" "$ok" "$skipped" "$errors"

    # Desktop notification
    if [[ $errors -gt 0 ]]; then
        rig_notify "rig" "${ok} ok, ${errors} failed — install finished in ${mins}m ${secs}s"
        exit 1
    else
        rig_notify "rig" "All ${ok} tools installed successfully in ${mins}m ${secs}s"
    fi

# ── Update ───────────────────────────────────────────────

# Upgrade only tools that are already installed
[script('bash')]
update:
    set -uo pipefail
    source "{{ rig_helpers }}"

    tools=($(rig_all_tools))
    max_retries="{{ max_retries }}"

    declare -a results=()
    declare -a messages=()
    declare -a run_tools=()
    errors=0
    skipped=0
    ok=0

    # Filter to only installed tools
    for tool in "${tools[@]}"; do
        if rig_is_installed "$tool"; then
            run_tools+=("$tool")
        fi
    done

    total=${#run_tools[@]}
    if [[ $total -eq 0 ]]; then
        echo "  No tools installed yet. Run 'just all' first."
        exit 0
    fi

    echo "  Upgrading $total installed tools..."
    echo ""
    start_time=$SECONDS

    for i in "${!run_tools[@]}"; do
        tool="${run_tools[$i]}"
        n=$((i + 1))
        printf "  [%d/%d] %-30s " "$n" "$total" "$tool"

        attempt=1
        delay=2
        output=""
        rc=1
        while [[ $attempt -le $max_retries ]]; do
            output=$(just "$tool" 2>&1) && rc=0 || rc=$?
            if [[ $rc -eq 0 ]]; then break; fi
            if [[ $attempt -lt $max_retries ]]; then
                printf "\033[33mretry %d/%d\033[0m " "$attempt" "$max_retries"
                sleep "$delay"
                delay=$((delay * 2))
            fi
            ((attempt++))
        done

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

    elapsed=$(( SECONDS - start_time ))
    mins=$(( elapsed / 60 ))
    secs=$(( elapsed % 60 ))

    printf "\n"
    printf "  ══════════════════════════════════════════════════════════════════\n"
    printf "  rig update complete  (%dm %ds)\n" "$mins" "$secs"
    printf "  ══════════════════════════════════════════════════════════════════\n\n"

    printf "  %-30s %-10s %s\n" "TOOL" "STATUS" "MESSAGE"
    printf "  %-30s %-10s %s\n" "----" "------" "-------"

    for i in "${!run_tools[@]}"; do
        tool="${run_tools[$i]}"
        status="${results[$i]}"
        msg="${messages[$i]}"
        case "$status" in
            ok) printf "  %-30s \033[32m%-10s\033[0m\n"    "$tool" "OK" ;;
            *)  printf "  %-30s \033[31m%-10s\033[0m %s\n" "$tool" "FAIL" "$msg" ;;
        esac
    done

    printf "\n  %s ok, %s failed\n\n" "$ok" "$errors"

    if [[ $errors -gt 0 ]]; then
        rig_notify "rig" "${ok} upgraded, ${errors} failed in ${mins}m ${secs}s"
        exit 1
    else
        rig_notify "rig" "${ok} tools upgraded in ${mins}m ${secs}s"
    fi

# ── Info ─────────────────────────────────────────────────

# Show details for a tool: version, path, install method
[script('bash')]
info tool:
    set -euo pipefail
    source "{{ rig_helpers }}"

    tool="{{ tool }}"

    # Validate tool name
    all=($(rig_all_tools))
    found=false
    for t in "${all[@]}"; do
        if [[ "$t" == "$tool" ]]; then found=true; break; fi
    done
    if [[ "$found" != "true" ]]; then
        echo "  unknown tool: $tool"
        echo "  run 'just --list' to see available tools"
        exit 1
    fi

    printf "\n"
    printf "  %-14s %s\n" "Tool:"     "$tool"
    printf "  %-14s %s\n" "Group:"    "$(rig_group "$tool")"
    printf "  %-14s %s\n" "Method:"   "$(rig_install_method "$tool")"

    if rig_is_installed "$tool"; then
        printf "  %-14s \033[32m%s\033[0m\n" "Installed:" "yes"
        printf "  %-14s %s\n" "Version:" "$(rig_version "$tool")"
        printf "  %-14s %s\n" "Path:"    "$(rig_which "$tool")"
    else
        printf "  %-14s \033[31m%s\033[0m\n" "Installed:" "no"
    fi

    printf "  %-14s %s\n" "Uninstall:" "$(rig_uninstall_cmd "$tool" "{{ host_os }}")"
    printf "\n"

# ── Outdated ─────────────────────────────────────────────

# Check installed tools for available updates
[script('bash')]
outdated:
    set -uo pipefail
    source "{{ rig_helpers }}"

    printf "\n  Checking for outdated packages...\n\n"

    found_outdated=0

    # ── Homebrew ──────────────────────────────────────────
    if command -v brew &>/dev/null; then
        brew_outdated=$(brew outdated --verbose 2>/dev/null || true)
        if [[ -n "$brew_outdated" ]]; then
            # Filter to only rig-managed tools
            all=($(rig_all_tools))
            for t in "${all[@]}"; do
                method=$(rig_install_method "$t")
                if [[ "$method" == "system" || "$method" == "cask" ]]; then
                    # Map tool name to brew package name
                    case "$t" in
                        jetbrains-mono-nerd-font) pkg="font-jetbrains-mono-nerd-font" ;;
                        op) pkg="1password-cli" ;;
                        *) pkg="$t" ;;
                    esac
                    match=$(echo "$brew_outdated" | grep -i "^$pkg " || true)
                    if [[ -n "$match" ]]; then
                        if [[ $found_outdated -eq 0 ]]; then
                            printf "  %-30s %-12s %s\n" "TOOL" "METHOD" "UPDATE"
                            printf "  %-30s %-12s %s\n" "----" "------" "------"
                        fi
                        printf "  %-30s %-12s %s\n" "$t" "brew" "$match"
                        ((found_outdated++))
                    fi
                fi
            done
        fi
    fi

    # ── npm ───────────────────────────────────────────────
    if command -v npm &>/dev/null; then
        npm_outdated=$(npm outdated -g --parseable 2>/dev/null || true)
        if [[ -n "$npm_outdated" ]]; then
            all=($(rig_all_tools))
            for t in "${all[@]}"; do
                if [[ "$(rig_install_method "$t")" == "npm" ]]; then
                    match=$(echo "$npm_outdated" | grep ":${t}@" || true)
                    if [[ -n "$match" ]]; then
                        current=$(echo "$match" | cut -d: -f3 | sed 's/.*@//')
                        latest=$(echo "$match" | cut -d: -f4 | sed 's/.*@//')
                        if [[ $found_outdated -eq 0 ]]; then
                            printf "  %-30s %-12s %s\n" "TOOL" "METHOD" "UPDATE"
                            printf "  %-30s %-12s %s\n" "----" "------" "------"
                        fi
                        printf "  %-30s %-12s %s → %s\n" "$t" "npm" "$current" "$latest"
                        ((found_outdated++))
                    fi
                fi
            done
        fi
    fi

    # ── pip/uv ────────────────────────────────────────────
    if command -v uv &>/dev/null; then
        uv_list=$(uv tool list 2>/dev/null || true)
        if [[ -n "$uv_list" ]]; then
            all=($(rig_all_tools))
            for t in "${all[@]}"; do
                if [[ "$(rig_install_method "$t")" == "uv" ]]; then
                    current=$(echo "$uv_list" | grep "^${t} " | awk '{print $2}' | tr -d 'v' || true)
                    if [[ -n "$current" ]]; then
                        latest=$(uv pip index versions "$t" 2>/dev/null | head -1 | awk '{print $NF}' | tr -d '()' || true)
                        if [[ -n "$latest" && "$current" != "$latest" ]]; then
                            if [[ $found_outdated -eq 0 ]]; then
                                printf "  %-30s %-12s %s\n" "TOOL" "METHOD" "UPDATE"
                                printf "  %-30s %-12s %s\n" "----" "------" "------"
                            fi
                            printf "  %-30s %-12s %s → %s\n" "$t" "uv" "$current" "$latest"
                            ((found_outdated++))
                        fi
                    fi
                fi
            done
        fi
    fi

    if [[ $found_outdated -eq 0 ]]; then
        printf "  \033[32mAll tools are up to date.\033[0m\n"
    else
        printf "\n  %d tool(s) have updates available. Run 'just update' to upgrade.\n" "$found_outdated"
    fi
    printf "\n"

# ── Uninstall ────────────────────────────────────────────

# Remove an installed tool
[script('bash')]
uninstall tool:
    set -euo pipefail
    source "{{ rig_helpers }}"

    tool="{{ tool }}"

    # Validate tool name
    all=($(rig_all_tools))
    found=false
    for t in "${all[@]}"; do
        if [[ "$t" == "$tool" ]]; then found=true; break; fi
    done
    if [[ "$found" != "true" ]]; then
        echo "  unknown tool: $tool"
        echo "  run 'just --list' to see available tools"
        exit 1
    fi

    if ! rig_is_installed "$tool"; then
        echo "  $tool is not installed."
        exit 0
    fi

    cmd=$(rig_uninstall_cmd "$tool" "{{ host_os }}")
    echo "  uninstalling $tool..."
    echo "  running: $cmd"
    eval "$cmd"

    if rig_is_installed "$tool"; then
        echo "  warning: $tool may still be installed"
        exit 1
    else
        echo "  $tool removed."
    fi

# ── Snapshot / Restore ───────────────────────────────────

# Save installed tools and versions to ~/.rig/snapshot.txt
[script('bash')]
snapshot:
    set -euo pipefail
    source "{{ rig_helpers }}"

    mkdir -p ~/.rig
    snapshot=~/.rig/snapshot.txt

    tools=($(rig_all_tools))
    count=0

    : > "$snapshot"
    for tool in "${tools[@]}"; do
        if rig_is_installed "$tool"; then
            version=$(rig_version "$tool")
            echo "${tool}|${version}" >> "$snapshot"
            ((count++))
        fi
    done

    printf "  Saved %d installed tools to %s\n" "$count" "$snapshot"

# Reinstall tools from ~/.rig/snapshot.txt
[script('bash')]
restore:
    set -uo pipefail
    source "{{ rig_helpers }}"

    snapshot=~/.rig/snapshot.txt
    if [[ ! -f "$snapshot" ]]; then
        echo "  No snapshot found at $snapshot"
        echo "  Run 'just snapshot' first."
        exit 1
    fi

    declare -a results=()
    declare -a tools=()
    errors=0
    ok=0

    while IFS='|' read -r tool version; do
        [[ -z "$tool" || "$tool" == \#* ]] && continue
        tools+=("$tool")
    done < "$snapshot"

    total=${#tools[@]}
    printf "  Restoring %d tools from snapshot...\n\n" "$total"
    start_time=$SECONDS

    for i in "${!tools[@]}"; do
        tool="${tools[$i]}"
        n=$((i + 1))
        printf "  [%d/%d] %-30s " "$n" "$total" "$tool"

        output=$(just "$tool" 2>&1) && rc=0 || rc=$?
        if [[ $rc -eq 0 ]]; then
            results+=("ok")
            ((ok++))
            printf "\033[32mok\033[0m\n"
        else
            results+=("error")
            ((errors++))
            printf "\033[31mfail\033[0m\n"
        fi
    done

    elapsed=$(( SECONDS - start_time ))
    mins=$(( elapsed / 60 ))
    secs=$(( elapsed % 60 ))

    printf "\n"
    printf "  ══════════════════════════════════════════════════════════════════\n"
    printf "  rig restore complete  (%dm %ds)\n" "$mins" "$secs"
    printf "  ══════════════════════════════════════════════════════════════════\n\n"
    printf "  %s ok, %s failed\n\n" "$ok" "$errors"

    if [[ $errors -gt 0 ]]; then
        rig_notify "rig" "Restore: ${ok} ok, ${errors} failed in ${mins}m ${secs}s"
        exit 1
    else
        rig_notify "rig" "Restored ${ok} tools in ${mins}m ${secs}s"
    fi

# ── Add ──────────────────────────────────────────────────

# Interactively add a new tool recipe
[script('bash')]
add:
    set -euo pipefail
    source "{{ rig_helpers }}"

    printf "\n  Add a new tool to rig\n\n"

    # Tool name
    printf "  Tool name (e.g. jq, my-tool): "
    read -r tool_name
    if [[ -z "$tool_name" ]]; then
        echo "  Aborted — no name given."
        exit 1
    fi

    # Check for duplicates
    all=($(rig_all_tools))
    for t in "${all[@]}"; do
        if [[ "$t" == "$tool_name" ]]; then
            echo "  '$tool_name' already exists as a rig recipe."
            exit 1
        fi
    done

    # Group
    printf "  Group (cli/python/node/go/rust/lsp/desktop): "
    read -r group
    file=$(rig_group_file "$group")
    if [[ -z "$file" ]]; then
        echo "  Unknown group: $group"
        exit 1
    fi
    file="{{ justfile_directory() }}/$file"

    # Install command
    printf "  Install command (e.g. brew install foo, cargo install foo): "
    read -r install_cmd
    if [[ -z "$install_cmd" ]]; then
        echo "  Aborted — no install command given."
        exit 1
    fi

    # Append recipe
    {
        echo ""
        echo "[group('$group')]"
        echo "${tool_name}:"
        echo "    @echo \"installing/upgrading ${tool_name}...\""
        echo "    @${install_cmd}"
    } >> "$file"

    printf "\n  Added '%s' to %s\n" "$tool_name" "$file"
    printf "  Run 'just %s' to install it.\n\n" "$tool_name"

# ── Diagnostics ──────────────────────────────────────────

# Check which declared tools are installed and which are missing
[script('bash')]
doctor:
    set -eo pipefail
    source "{{ rig_helpers }}"

    tools=($(rig_all_tools))
    missing=0
    found=0

    printf "\n  %-30s %s\n" "TOOL" "STATUS"
    printf "  %-30s %s\n" "----" "------"

    for tool in "${tools[@]}"; do
        if rig_is_installed "$tool"; then
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
