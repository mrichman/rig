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
fd: rust
    @echo "installing/upgrading fd..."
    @cargo install fd-find

[group('cli')]
eza: rust
    @echo "installing/upgrading eza..."
    @cargo install eza

[group('cli')]
zoxide: rust
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
        case "{{ host_arch }}" in
            x86_64)  karch=amd64 ;;
            aarch64) karch=arm64 ;;
            *)       karch="{{ host_arch }}" ;;
        esac
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${karch}/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm kubectl
    fi

[group('cli')]
gh:
    @echo "installing/upgrading gh..."
    @{{ sys_install }} gh

[group('cli')]
[script('bash')]
terraform:
    set -euo pipefail
    echo "installing/upgrading terraform..."
    if [[ "{{ host_os }}" == "macos" ]]; then
        brew install terraform
        exit 0
    fi
    case "{{ host_arch }}" in
        x86_64)  tf_arch=amd64 ;;
        aarch64) tf_arch=arm64 ;;
        *) echo "  unsupported arch: {{ host_arch }}"; exit 1 ;;
    esac
    version=$(curl -fsSL https://checkpoint-api.hashicorp.com/v1/check/terraform \
        | grep -oE '"current_version":"[^"]+"' | cut -d'"' -f4)
    [[ -z "$version" ]] && { echo "  could not resolve latest terraform version"; exit 1; }
    tmp=$(mktemp -d)
    curl -fsSLo "$tmp/tf.zip" "https://releases.hashicorp.com/terraform/${version}/terraform_${version}_linux_${tf_arch}.zip"
    unzip -o "$tmp/tf.zip" -d "$tmp" >/dev/null
    sudo install -m 0755 "$tmp/terraform" /usr/local/bin/terraform
    rm -rf "$tmp"

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
    source "{{ rig_helpers }}"
    echo "installing/upgrading 1password-cli..."
    if [[ "{{ host_os }}" == "macos" ]]; then
        brew install --cask 1password-cli
        exit 0
    fi
    family=$(rig_pkg_family)
    if [[ "$family" == "deb" ]]; then
        # Upstream apt repo — Debian/Ubuntu have no "1password-cli" package by default.
        keyring=/usr/share/keyrings/1password-archive-keyring.gpg
        listfile=/etc/apt/sources.list.d/1password.list
        if [[ ! -s "$keyring" ]]; then
            curl -fsS https://downloads.1password.com/linux/keys/1password.asc \
                | sudo gpg --dearmor --yes -o "$keyring"
        fi
        if [[ ! -f "$listfile" ]]; then
            echo "deb [arch=$(dpkg --print-architecture) signed-by=${keyring}] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" \
                | sudo tee "$listfile" >/dev/null
        fi
        sudo apt-get update -qq
        sudo apt-get install -y 1password-cli
    elif [[ "$family" == "rpm" ]]; then
        sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc
        {
            printf '[1password]\n'
            printf 'name=1Password Stable Channel\n'
            printf 'baseurl=https://downloads.1password.com/linux/rpm/stable/$basearch\n'
            printf 'enabled=1\n'
            printf 'gpgcheck=1\n'
            printf 'repo_gpgcheck=1\n'
            printf 'gpgkey=https://downloads.1password.com/linux/keys/1password.asc\n'
        } | sudo tee /etc/yum.repos.d/1password.repo >/dev/null
        if command -v dnf &>/dev/null; then
            sudo dnf install -y 1password-cli
        else
            sudo yum install -y 1password-cli
        fi
    else
        echo "  skipping 1password-cli: no deb/rpm package for this distro"
        exit 0
    fi

[group('cli')]
claude-code:
    @echo "installing/upgrading claude-code..."
    @curl -fsSL https://claude.ai/install.sh | bash

[group('cli')]
typst: rust
    @echo "installing/upgrading typst..."
    @cargo install --locked typst-cli
