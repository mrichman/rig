# Python tools — installed via uv

# Custom install script (not from a package manager)
[group('python')]
uv:
    @echo "installing/upgrading uv..."
    @curl -LsSf https://astral.sh/uv/install.sh | sh

[group('python')]
ruff:
    @echo "installing/upgrading ruff..."
    @uv tool install ruff

# Pattern 2: pin a version
[group('python')]
black:
    @echo "installing/upgrading black..."
    @uv tool install black==24.2.0

[group('python')]
isort:
    @echo "installing/upgrading isort..."
    @uv tool install isort

[group('python')]
pyright:
    @echo "installing/upgrading pyright..."
    @uv tool install pyright

[group('python')]
pytest:
    @echo "installing/upgrading pytest..."
    @uv tool install pytest
