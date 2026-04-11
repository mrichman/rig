# Desktop applications

# Install all desktop apps
[group('desktop')]
desktop: kitty ghostty zed jetbrains-mono-nerd-font appcleaner basictex brave-browser drawio firefox git-credential-manager google-chrome google-drive iina keka maccy netnewswire obsidian ollama-app skim stats transmission vscodium zoom

[group('desktop')]
[script('bash')]
kitty:
    set -euo pipefail
    echo "installing/upgrading kitty..."
    if [[ "{{ host_os }}" == "macos" ]]; then
        brew install --cask kitty
    else
        curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
    fi

[group('desktop')]
[script('bash')]
ghostty:
    set -euo pipefail
    source "{{ rig_helpers }}"
    rig_skip_if_unsupported ghostty
    echo "installing/upgrading ghostty..."
    brew install --cask ghostty

[group('desktop')]
[script('bash')]
zed:
    set -euo pipefail
    echo "installing/upgrading zed..."
    if [[ "{{ host_os }}" == "macos" ]]; then
        brew install --cask zed
    else
        curl -fsSL https://zed.dev/install.sh | sh
    fi

[group('desktop')]
[script('bash')]
jetbrains-mono-nerd-font:
    set -euo pipefail
    echo "installing/upgrading JetBrains Mono Nerd Font..."
    if [[ "{{ host_os }}" == "macos" ]]; then
        brew install --cask font-jetbrains-mono-nerd-font
    else
        tmp="$(mktemp -d)"
        curl -L -o "$tmp/jbmono.tar.xz" \
            "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
        mkdir -p ~/.local/share/fonts
        tar xf "$tmp/jbmono.tar.xz" -C ~/.local/share/fonts
        fc-cache -fv ~/.local/share/fonts
        rm -rf "$tmp"
    fi

[group('desktop')]
[script('bash')]
appcleaner:
    set -euo pipefail
    source "{{ rig_helpers }}"
    rig_skip_if_unsupported appcleaner
    echo "installing/upgrading appcleaner..."
    brew install --cask appcleaner

[group('desktop')]
[script('bash')]
basictex:
    set -euo pipefail
    source "{{ rig_helpers }}"
    rig_skip_if_unsupported basictex
    echo "installing/upgrading basictex..."
    brew install --cask basictex

[group('desktop')]
[script('bash')]
brave-browser:
    set -euo pipefail
    echo "installing/upgrading brave-browser..."
    if [[ "{{ host_os }}" == "macos" ]]; then
        brew install --cask brave-browser
    else
        curl -fsS https://dl.brave.com/install.sh | sh
    fi

[group('desktop')]
[script('bash')]
drawio:
    set -euo pipefail
    source "{{ rig_helpers }}"
    echo "installing/upgrading drawio..."
    if [[ "{{ host_os }}" == "macos" ]]; then
        brew install --cask drawio
        exit 0
    fi
    case "{{ host_arch }}" in
        x86_64)  arch_deb=amd64; arch_rpm=x86_64 ;;
        aarch64) arch_deb=arm64; arch_rpm=aarch64 ;;
        *) echo "  skipping drawio: unsupported arch {{ host_arch }}"; exit 0 ;;
    esac
    family=$(rig_pkg_family)
    case "$family" in
        deb)
            url=$(rig_gh_latest_asset jgraph/drawio-desktop "drawio-${arch_deb}-.*\\.deb$")
            [[ -z "$url" ]] && { echo "  could not find drawio .deb asset"; exit 1; }
            rig_install_deb "$url" ;;
        rpm)
            url=$(rig_gh_latest_asset jgraph/drawio-desktop "drawio-${arch_rpm}-.*\\.rpm$")
            [[ -z "$url" ]] && { echo "  could not find drawio .rpm asset"; exit 1; }
            rig_install_rpm "$url" ;;
        *)
            echo "  skipping drawio: no deb/rpm package for this distro"
            exit 0 ;;
    esac

[group('desktop')]
[script('bash')]
firefox:
    set -euo pipefail
    echo "installing/upgrading firefox..."
    if [[ "{{ host_os }}" == "macos" ]]; then
        brew install --cask firefox
    else
        {{ sys_install }} firefox
    fi

[group('desktop')]
[script('bash')]
git-credential-manager:
    set -euo pipefail
    source "{{ rig_helpers }}"
    echo "installing/upgrading git-credential-manager..."
    if [[ "{{ host_os }}" == "macos" ]]; then
        brew install --cask git-credential-manager
        exit 0
    fi
    family=$(rig_pkg_family)
    if [[ "$family" != "deb" ]]; then
        echo "  skipping git-credential-manager: upstream ships .deb only — use the tarball from https://github.com/git-ecosystem/git-credential-manager/releases"
        exit 0
    fi
    case "{{ host_arch }}" in
        x86_64)  arch_tag=x64 ;;
        aarch64) arch_tag=arm64 ;;
        *) echo "  skipping git-credential-manager: unsupported arch {{ host_arch }}"; exit 0 ;;
    esac
    url=$(rig_gh_latest_asset git-ecosystem/git-credential-manager "gcm-linux-${arch_tag}-[0-9][^\"]*\\.deb$")
    [[ -z "$url" ]] && { echo "  could not find gcm .deb asset"; exit 1; }
    rig_install_deb "$url"

[group('desktop')]
[script('bash')]
google-chrome:
    set -euo pipefail
    source "{{ rig_helpers }}"
    rig_skip_if_unsupported google-chrome
    echo "installing/upgrading google-chrome..."
    if [[ "{{ host_os }}" == "macos" ]]; then
        brew install --cask google-chrome
        exit 0
    fi
    family=$(rig_pkg_family)
    case "$family" in
        deb) rig_install_deb "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" ;;
        rpm) rig_install_rpm "https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm" ;;
        *)   echo "  skipping google-chrome: no deb/rpm package for this distro"; exit 0 ;;
    esac

[group('desktop')]
[script('bash')]
google-drive:
    set -euo pipefail
    source "{{ rig_helpers }}"
    rig_skip_if_unsupported google-drive
    echo "installing/upgrading google-drive..."
    brew install --cask google-drive

[group('desktop')]
[script('bash')]
iina:
    set -euo pipefail
    source "{{ rig_helpers }}"
    rig_skip_if_unsupported iina
    echo "installing/upgrading iina..."
    brew install --cask iina

[group('desktop')]
[script('bash')]
keka:
    set -euo pipefail
    source "{{ rig_helpers }}"
    rig_skip_if_unsupported keka
    echo "installing/upgrading keka..."
    brew install --cask keka

[group('desktop')]
[script('bash')]
maccy:
    set -euo pipefail
    source "{{ rig_helpers }}"
    rig_skip_if_unsupported maccy
    echo "installing/upgrading maccy..."
    brew install --cask maccy

[group('desktop')]
[script('bash')]
netnewswire:
    set -euo pipefail
    source "{{ rig_helpers }}"
    rig_skip_if_unsupported netnewswire
    echo "installing/upgrading netnewswire..."
    brew install --cask netnewswire

[group('desktop')]
[script('bash')]
obsidian:
    set -euo pipefail
    source "{{ rig_helpers }}"
    echo "installing/upgrading obsidian..."
    if [[ "{{ host_os }}" == "macos" ]]; then
        brew install --cask obsidian
        exit 0
    fi
    family=$(rig_pkg_family)
    if [[ "$family" == "deb" && "{{ host_arch }}" == "x86_64" ]]; then
        url=$(rig_gh_latest_asset obsidianmd/obsidian-releases "obsidian_[0-9][^\"]*_amd64\\.deb$")
        [[ -z "$url" ]] && { echo "  could not find obsidian .deb asset"; exit 1; }
        rig_install_deb "$url"
    elif command -v flatpak &>/dev/null; then
        sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        sudo flatpak install -y flathub md.obsidian.Obsidian
    else
        echo "  skipping obsidian: no .deb for this arch and flatpak not installed — grab the AppImage from https://obsidian.md"
        exit 0
    fi

[group('desktop')]
[script('bash')]
ollama-app:
    set -euo pipefail
    echo "installing/upgrading ollama..."
    if [[ "{{ host_os }}" == "macos" ]]; then
        brew install --cask ollama
    else
        curl -fsSL https://ollama.com/install.sh | sh
    fi

[group('desktop')]
[script('bash')]
skim:
    set -euo pipefail
    source "{{ rig_helpers }}"
    rig_skip_if_unsupported skim
    echo "installing/upgrading skim..."
    brew install --cask skim

[group('desktop')]
[script('bash')]
stats:
    set -euo pipefail
    source "{{ rig_helpers }}"
    rig_skip_if_unsupported stats
    echo "installing/upgrading stats..."
    brew install --cask stats

[group('desktop')]
[script('bash')]
transmission:
    set -euo pipefail
    echo "installing/upgrading transmission..."
    if [[ "{{ host_os }}" == "macos" ]]; then
        brew install --cask transmission
    else
        {{ sys_install }} transmission
    fi

[group('desktop')]
[script('bash')]
vscodium:
    set -euo pipefail
    source "{{ rig_helpers }}"
    echo "installing/upgrading vscodium..."
    if [[ "{{ host_os }}" == "macos" ]]; then
        brew install --cask vscodium
        exit 0
    fi
    case "{{ host_arch }}" in
        x86_64)  arch_deb=amd64; arch_rpm=x86_64 ;;
        aarch64) arch_deb=arm64; arch_rpm=aarch64 ;;
        *) echo "  skipping vscodium: unsupported arch {{ host_arch }}"; exit 0 ;;
    esac
    family=$(rig_pkg_family)
    case "$family" in
        deb)
            url=$(rig_gh_latest_asset VSCodium/vscodium "codium_[0-9][^\"]*_${arch_deb}\\.deb$")
            [[ -z "$url" ]] && { echo "  could not find vscodium .deb asset"; exit 1; }
            rig_install_deb "$url" ;;
        rpm)
            url=$(rig_gh_latest_asset VSCodium/vscodium "codium-[0-9][^\"]*\\.${arch_rpm}\\.rpm$")
            [[ -z "$url" ]] && { echo "  could not find vscodium .rpm asset"; exit 1; }
            rig_install_rpm "$url" ;;
        *)
            echo "  skipping vscodium: no deb/rpm package for this distro"
            exit 0 ;;
    esac

[group('desktop')]
[script('bash')]
zoom:
    set -euo pipefail
    source "{{ rig_helpers }}"
    rig_skip_if_unsupported zoom
    echo "installing/upgrading zoom..."
    if [[ "{{ host_os }}" == "macos" ]]; then
        brew install --cask zoom
        exit 0
    fi
    family=$(rig_pkg_family)
    case "$family" in
        deb) rig_install_deb "https://zoom.us/client/latest/zoom_amd64.deb" ;;
        rpm) rig_install_rpm "https://zoom.us/client/latest/zoom_x86_64.rpm" ;;
        *)   echo "  skipping zoom: no deb/rpm package for this distro"; exit 0 ;;
    esac
