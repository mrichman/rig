# Desktop applications

# Install all desktop apps
[group('desktop')]
desktop: kitty ghostty zed jetbrains-mono-nerd-font appcleaner basictex brave-browser drawio firefox git-credential-manager google-chrome google-drive iina keka maccy netnewswire obsidian ollama-app skim stats transmission zoom

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

[group('desktop')]
appcleaner:
    @echo "installing/upgrading appcleaner..."
    @brew install --cask appcleaner

[group('desktop')]
basictex:
    @echo "installing/upgrading basictex..."
    @brew install --cask basictex

[group('desktop')]
brave-browser:
    @echo "installing/upgrading brave-browser..."
    @brew install --cask brave-browser

[group('desktop')]
drawio:
    @echo "installing/upgrading drawio..."
    @brew install --cask drawio

[group('desktop')]
firefox:
    @echo "installing/upgrading firefox..."
    @brew install --cask firefox

[group('desktop')]
git-credential-manager:
    @echo "installing/upgrading git-credential-manager..."
    @brew install --cask git-credential-manager

[group('desktop')]
google-chrome:
    @echo "installing/upgrading google-chrome..."
    @brew install --cask google-chrome

[group('desktop')]
google-drive:
    @echo "installing/upgrading google-drive..."
    @brew install --cask google-drive

[group('desktop')]
iina:
    @echo "installing/upgrading iina..."
    @brew install --cask iina

[group('desktop')]
keka:
    @echo "installing/upgrading keka..."
    @brew install --cask keka

[group('desktop')]
maccy:
    @echo "installing/upgrading maccy..."
    @brew install --cask maccy

[group('desktop')]
netnewswire:
    @echo "installing/upgrading netnewswire..."
    @brew install --cask netnewswire

[group('desktop')]
obsidian:
    @echo "installing/upgrading obsidian..."
    @brew install --cask obsidian

[group('desktop')]
ollama-app:
    @echo "installing/upgrading ollama..."
    @brew install --cask ollama

[group('desktop')]
skim:
    @echo "installing/upgrading skim..."
    @brew install --cask skim

[group('desktop')]
stats:
    @echo "installing/upgrading stats..."
    @brew install --cask stats

[group('desktop')]
transmission:
    @echo "installing/upgrading transmission..."
    @brew install --cask transmission

[group('desktop')]
zoom:
    @echo "installing/upgrading zoom..."
    @brew install --cask zoom
