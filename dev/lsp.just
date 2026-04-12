# LSP servers

[group('lsp')]
bash-language-server:
    @echo "installing/upgrading bash-language-server..."
    @{{ npm_install }} bash-language-server

[group('lsp')]
typescript-language-server:
    @echo "installing/upgrading typescript-language-server..."
    @{{ npm_install }} typescript-language-server

[group('lsp')]
[script('bash')]
lua-language-server:
    set -euo pipefail
    source "{{ rig_helpers }}"
    echo "installing/upgrading lua-language-server..."
    case "{{ host_os }}-{{ host_arch }}" in
        macos-aarch64) platform="darwin-arm64" ;;
        macos-x86_64)  platform="darwin-x64"   ;;
        linux-aarch64) platform="linux-arm64"  ;;
        linux-x86_64)  platform="linux-x64"    ;;
        *) echo "unsupported platform: {{ host_os }}-{{ host_arch }}"; exit 1 ;;
    esac
    version=$(rig_gh_latest_tag LuaLS/lua-language-server)
    [[ -z "$version" ]] && { echo "  could not resolve lua-language-server version"; exit 1; }
    cd /tmp
    curl -fL -o lls.tar.gz \
        "https://github.com/LuaLS/lua-language-server/releases/download/${version}/lua-language-server-${version}-${platform}.tar.gz"
    mkdir -p ~/.local/lib/lua-language-server
    tar xzf lls.tar.gz -C ~/.local/lib/lua-language-server
    mkdir -p ~/.local/bin
    ln -sf ~/.local/lib/lua-language-server/bin/lua-language-server ~/.local/bin/lua-language-server
    rm lls.tar.gz

[group('lsp')]
[script('bash')]
tinymist:
    set -euo pipefail
    source "{{ rig_helpers }}"
    echo "installing/upgrading tinymist..."
    if [[ "{{ host_os }}" == "macos" ]]; then
        brew install tinymist
        exit 0
    fi
    case "{{ host_arch }}" in
        x86_64)  asset=tinymist-linux-x64 ;;
        aarch64) asset=tinymist-linux-arm64 ;;
        *) echo "  skipping tinymist: unsupported arch {{ host_arch }}"; exit 0 ;;
    esac
    url=$(rig_gh_latest_asset Myriad-Dreamin/tinymist "/${asset}\$")
    [[ -z "$url" ]] && { echo "  could not find tinymist asset $asset"; exit 1; }
    mkdir -p "$HOME/.local/bin"
    curl -fsSLo "$HOME/.local/bin/tinymist" "$url"
    chmod +x "$HOME/.local/bin/tinymist"
