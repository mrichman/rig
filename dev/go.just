# Go tools — installed via go install

# Pattern 3: target name differs from full module path
[group('go')]
gopls:
    @echo "installing/upgrading gopls..."
    @go install golang.org/x/tools/gopls@latest

[group('go')]
golangci-lint:
    @echo "installing/upgrading golangci-lint..."
    @{{ sys_install }} golangci-lint
