# Rust tools — installed via cargo

[group('rust')]
cargo-edit:
    @echo "installing/upgrading cargo-edit..."
    @cargo install cargo-edit

[group('rust')]
cargo-watch:
    @echo "installing/upgrading cargo-watch..."
    @cargo install cargo-watch
