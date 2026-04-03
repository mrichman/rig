# CLI tools — system packages and cargo

[group('cli')]
ripgrep:
    @echo "installing/upgrading ripgrep..."
    @{{ sys_install }} ripgrep

[group('cli')]
jq:
    @echo "installing/upgrading jq..."
    @{{ sys_install }} jq

[group('cli')]
bat:
    @echo "installing/upgrading bat..."
    @{{ sys_install }} bat

[group('cli')]
fzf:
    @echo "installing/upgrading fzf..."
    @{{ sys_install }} fzf

[group('cli')]
htop:
    @echo "installing/upgrading htop..."
    @{{ sys_install }} htop

[group('cli')]
tmux:
    @echo "installing/upgrading tmux..."
    @{{ sys_install }} tmux

# Target name differs from cargo package name
[group('cli')]
fd:
    @echo "installing/upgrading fd..."
    @cargo install fd-find

[group('cli')]
eza:
    @echo "installing/upgrading eza..."
    @cargo install eza

[group('cli')]
zoxide:
    @echo "installing/upgrading zoxide..."
    @cargo install zoxide

[group('cli')]
fish:
    @echo "installing/upgrading fish..."
    @{{ sys_install }} fish

[group('cli')]
awscli:
    @echo "installing/upgrading awscli..."
    @{{ sys_install }} awscli

[group('cli')]
starship:
    @echo "installing/upgrading starship..."
    @curl -sS https://starship.rs/install.sh | sh -s -- -y

[group('cli')]
neovim:
    @echo "installing/upgrading neovim..."
    @{{ sys_install }} neovim

# Fish plugin manager — requires fish
[group('cli')]
fisher:
    @echo "installing/upgrading fisher..."
    @fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"

[group('cli')]
[script('bash')]
docker:
    set -euo pipefail
    echo "installing/upgrading docker..."
    if [[ "{{ host_os }}" == "macos" ]]; then
        brew install --cask docker
    else
        curl -fsSL https://get.docker.com | sh
    fi

[group('cli')]
[script('bash')]
kubectl:
    set -euo pipefail
    echo "installing/upgrading kubectl..."
    if [[ "{{ host_os }}" == "macos" ]]; then
        brew install kubectl
    else
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/{{ host_arch }}/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm kubectl
    fi

[group('cli')]
gh:
    @echo "installing/upgrading gh..."
    @{{ sys_install }} gh

[group('cli')]
terraform:
    @echo "installing/upgrading terraform..."
    @{{ sys_install }} terraform

[group('cli')]
[script('bash')]
helm:
    set -euo pipefail
    echo "installing/upgrading helm..."
    if [[ "{{ host_os }}" == "macos" ]]; then
        brew install helm
    else
        curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi

[group('cli')]
[script('bash')]
op:
    set -euo pipefail
    echo "installing/upgrading 1password-cli..."
    if [[ "{{ host_os }}" == "macos" ]]; then
        brew install --cask 1password-cli
    else
        {{ sys_install }} 1password-cli
    fi

[group('cli')]
claude-code:
    @echo "installing/upgrading claude-code..."
    @curl -fsSL https://claude.ai/install.sh | bash

[group('cli')]
typst:
    @echo "installing/upgrading typst..."
    @cargo install --locked typst-cli
