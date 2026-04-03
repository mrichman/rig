# rig

Rig up your dev machine from a single [justfile](https://github.com/casey/just). One command to install anything.

## The problem

A developer's machine accumulates tools from half a dozen package managers. ripgrep came from apt, eza from cargo, ruff from uv, gopls from go install, prettier from npm, and Neovim from a tarball. Each has its own install syntax, its own upgrade command, its own way of pinning versions.

Six months later you get a new machine. What do you even have installed? How did you install each one? Which version? You spend a day re-discovering what you had and how to get it back.

## The fix

Not another tool — a text file you already understand. Declare every tool you care about, grouped by purpose, in a set of `.just` files. The justfile detects your OS and distro, picks the right package manager, and gives you three levels of granularity:

```bash
just ripgrep      # one package
just cli           # one group
just all           # everything
```

We use [just](https://github.com/casey/just) rather than Make because it has built-in OS detection, grouped recipe listings, and an interactive fzf chooser — all things you'd have to bolt on to a Makefile. And unlike Nix or Ansible, there's nothing new to learn if you can read a shell script.

No daemon, no hidden state, no lock-in. If something fails, you read a shell command. If you want to add a tool, you add one recipe. If you want to set up a new machine, you clone the repo and run `just all`.

## Quick start

```bash
# install just (skip if you already have it)
./bootstrap.sh

# install one package
just ripgrep

# install a group
just cli

# install everything
just all

# interactive fuzzy installer (built into just)
just --choose
```

## How it works

A main `justfile` imports one `.just` file per category:

```
justfile
├── dev/
│   ├── cli.just       # system packages + cargo
│   ├── python.just    # uv tool install
│   ├── node.just      # npm
│   ├── go.just        # go install
│   ├── rust.just      # cargo
│   └── lsp.just       # LSP servers
└── desktop/
    └── apps.just      # desktop applications
```

The justfile detects your OS and distro at startup, then sets `sys_install` to the right package manager:

| OS | `sys_install` |
|---|---|
| macOS | `brew install` |
| Ubuntu / Debian | `sudo apt-get install -y` |
| Fedora | `sudo dnf install -y` |
| CentOS / RHEL | `sudo yum install -y` |
| Arch / Manjaro | `sudo pacman -S --noconfirm` |
| openSUSE | `sudo zypper install -y` |

Each recipe uses `{{ sys_install }}` so the same justfile works on any supported platform:

```just
[group('cli')]
ripgrep:
    @echo "installing/upgrading ripgrep..."
    @{{ sys_install }} ripgrep
```

Cross-platform managers (cargo, uv, go, npm) work unchanged everywhere.

## Three patterns for adding a package

**Pattern 1** — name matches, use your system package manager:

```just
# dev/cli.just
[group('cli')]
htop:
    @echo "installing/upgrading htop..."
    @{{ sys_install }} htop
```

Then add `htop` to the group dependency list in the main `justfile`:

```just
cli: ripgrep jq bat fzf htop tmux eza zoxide fd
```

**Pattern 2** — pin a version:

```just
# dev/python.just
[group('python')]
black:
    @echo "installing/upgrading black..."
    @uv tool install black==24.2.0
```

**Pattern 3** — target name differs from package name:

```just
# dev/cli.just — `just fd` runs `cargo install fd-find`
[group('cli')]
fd:
    @echo "installing/upgrading fd..."
    @cargo install fd-find
```

**Custom install scripts** — when a tool isn't in any package manager:

```just
[group('python')]
uv:
    @echo "installing/upgrading uv..."
    @curl -LsSf https://astral.sh/uv/install.sh | sh
```

## Granularity

Three levels, same system:

```bash
just ripgrep      # one package
just cli           # one group
just all           # everything
```

## Interactive installer

`just` has built-in fzf support:

```bash
just --choose
```

Add a dry-run preview pane:

```bash
just --choose --chooser 'fzf --multi --preview "just --dry-run {}"'
```

## Cleanup

```bash
just clean
```

Purges caches for every detected package manager (brew, apt, dnf, cargo, uv, npm, go).

## Bootstrap

On a fresh machine, run the bootstrap script first after cloning this repo:

```bash
./bootstrap.sh
```

It installs `just` via your system package manager (brew, apt, dnf, pacman, zypper) or falls back to the official prebuilt binary.

---

Built with [Claude Code](https://claude.ai/code).
