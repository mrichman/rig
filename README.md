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
├── lib/
│   ├── tools.tsv      # tool registry (single source of truth)
│   └── rig.sh         # shared helper functions
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

`lib/tools.tsv` is the registry that maps every tool to its binary name, group, install method, and brew package name. The helper functions in `lib/rig.sh` read from this file — no metadata is hardcoded in multiple places.

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

## Adding a new tool

The quickest way is the interactive command:

```bash
just add
```

It prompts for the tool name, group, install method, and install command, then writes both the recipe and the registry entry for you.

To add a tool manually, you need to touch two (optionally three) files:

### 1. Register the tool in `lib/tools.tsv`

This is the single source of truth for all tool metadata. Add one tab-separated line:

```
# tool	binary	group	method	pkg	uninstall_cmd
mytool	-	cli	system	-	-
```

| Field | Description | Default (`-`) |
|---|---|---|
| `tool` | Recipe/tool name | — |
| `binary` | CLI binary name (for PATH detection) | same as tool |
| `group` | `cli`, `python`, `node`, `go`, `rust`, `lsp`, or `desktop` | — |
| `method` | `system`, `cask`, `cargo`, `go`, `npm`, `uv`, or `custom` | — |
| `pkg` | Brew package name (when it differs from tool name) | same as tool |
| `uninstall_cmd` | Custom uninstall command (when the default isn't enough) | auto-generated from method |

### 2. Add a recipe to the appropriate `.just` file

Pick the file that matches the group:

| Group | File |
|---|---|
| cli | `dev/cli.just` |
| python | `dev/python.just` |
| node | `dev/node.just` |
| go | `dev/go.just` |
| rust | `dev/rust.just` |
| lsp | `dev/lsp.just` |
| desktop | `desktop/apps.just` |

A minimal recipe looks like:

```just
[group('cli')]
mytool:
    @echo "installing/upgrading mytool..."
    @{{ sys_install }} mytool
```

Common variations:

```just
# Brew cask (macOS desktop app)
@brew install --cask myapp

# Cargo with flags
@cargo install --locked mytool-cli

# Pin a version
@uv tool install black==24.2.0

# Custom install script
@curl -LsSf https://example.com/install.sh | sh
```

### 3. (Optional) Add to the group dependency list

In the main `justfile`, add the tool name to its group target so `just cli` (or whichever group) includes it:

```just
cli: ripgrep jq bat fzf htop ... mytool
```

This step is only needed if you want the tool included when running the group target directly. Tools registered in `lib/tools.tsv` are always included in `just all`, `just update`, and `just doctor` regardless.

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
