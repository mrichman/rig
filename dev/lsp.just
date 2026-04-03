# LSP servers

[group('lsp')]
bash-language-server:
    @echo "installing/upgrading bash-language-server..."
    @{{ npm_install }} bash-language-server

[group('lsp')]
typescript-language-server:
    @echo "installing/upgrading typescript-language-server..."
    @{{ npm_install }} typescript-language-server

# Custom install: not in any package manager
[group('lsp')]
[script('bash')]
lua-language-server:
    set -euo pipefail
    echo "installing/upgrading lua-language-server..."
    case "{{ host_os }}-{{ host_arch }}" in
        macos-aarch64) platform="darwin-arm64" ;;
        macos-x86_64)  platform="darwin-x64"   ;;
        linux-aarch64) platform="linux-arm64"  ;;
        linux-x86_64)  platform="linux-x64"    ;;
        *) echo "unsupported platform: {{ host_os }}-{{ host_arch }}"; exit 1 ;;
    esac
    cd /tmp
    curl -L -o lls.tar.gz \
        "https://github.com/LuaLS/lua-language-server/releases/latest/download/lua-language-server-${platform}.tar.gz"
    mkdir -p ~/.local/lib/lua-language-server
    tar xzf lls.tar.gz -C ~/.local/lib/lua-language-server
    mkdir -p ~/.local/bin
    ln -sf ~/.local/lib/lua-language-server/bin/lua-language-server ~/.local/bin/lua-language-server
    rm lls.tar.gz
