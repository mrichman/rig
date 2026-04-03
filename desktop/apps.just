# Desktop applications

# Install all desktop apps
[group('desktop')]
desktop: kitty ghostty zed jetbrains-mono-nerd-font

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
    echo "installing/upgrading ghostty..."
    if [[ "{{ host_os }}" == "macos" ]]; then
        brew install --cask ghostty
    else
        {{ sys_install }} ghostty
    fi

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
