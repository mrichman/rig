# Go tools — installed via go install

# Pattern 3: target name differs from full module path
[group('go')]
gopls:
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
