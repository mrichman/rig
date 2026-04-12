# Rust tools — installed via cargo

# Bootstrap rust toolchain (rustup + cargo) if not already present.
[group('rust')]
[script('bash')]
rust:
    set -euo pipefail
    if command -v cargo &>/dev/null; then
        echo "rust already installed: $(cargo --version)"
        exit 0
    fi
    echo "installing rust (rustup)..."
    if [[ "{{ host_os }}" == "macos" ]]; then
        brew install rustup-init
        rustup-init -y --no-modify-path --default-toolchain stable
    else
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
            | sh -s -- -y --no-modify-path --default-toolchain stable
    fi

[group('rust')]
cargo-edit: rust
    @echo "installing/upgrading cargo-edit..."
    @cargo install cargo-edit

[group('rust')]
cargo-watch: rust
    @echo "installing/upgrading cargo-watch..."
    @cargo install cargo-watch
