# Go tools — installed via go install

# Bootstrap Go toolchain if not already present.
[group('go')]
[script('bash')]
go:
    set -euo pipefail
    if command -v go &>/dev/null; then
        echo "go already installed: $(go version)"
        exit 0
    fi
    echo "installing go..."
    if [[ "{{ host_os }}" == "macos" ]]; then
        brew install go
        exit 0
    fi
    case "{{ host_arch }}" in
        x86_64)  goarch=amd64 ;;
        aarch64) goarch=arm64 ;;
        *) echo "  unsupported arch: {{ host_arch }}"; exit 1 ;;
    esac
    version=$(curl -fsSL https://go.dev/VERSION?m=text | head -1)
    [[ -z "$version" ]] && { echo "  could not resolve latest go version"; exit 1; }
    tmp=$(mktemp -d)
    curl -fsSLo "$tmp/go.tgz" "https://go.dev/dl/${version}.linux-${goarch}.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "$tmp/go.tgz"
    rm -rf "$tmp"
    # Ensure go is findable even before shells reload
    sudo ln -sf /usr/local/go/bin/go /usr/local/bin/go
    sudo ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt

# Pattern 3: target name differs from full module path
[group('go')]
gopls: go
    @echo "installing/upgrading gopls..."
    @go install golang.org/x/tools/gopls@latest

[group('go')]
[script('bash')]
golangci-lint:
    set -euo pipefail
    echo "installing/upgrading golangci-lint..."
    if [[ "{{ host_os }}" == "macos" ]]; then
        brew install golangci-lint
    else
        target="${HOME}/.local/bin"
        mkdir -p "$target"
        curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh \
            | sh -s -- -b "$target"
    fi
