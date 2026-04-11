# Node tools — installed via npm

[group('node')]
[script('bash')]
nodejs:
    set -euo pipefail
    echo "installing/upgrading nodejs..."
    if [[ "{{ host_os }}" == "macos" ]]; then
        brew install node
    else
        {{ sys_install }} nodejs npm
    fi

[group('node')]
prettier:
    @echo "installing/upgrading prettier..."
    @{{ npm_install }} prettier

[group('node')]
eslint:
    @echo "installing/upgrading eslint..."
    @{{ npm_install }} eslint
