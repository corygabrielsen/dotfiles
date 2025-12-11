# Dotfiles

Personal dotfiles managed via symlinks. Zero dependencies beyond `make` and `git`.

## Quick Start

```bash
git clone git@github.com:corygabrielsen/dotfiles.git ~/code/dotfiles
cd ~/code/dotfiles
make
```

**One-liner** (fresh machine):
```bash
sudo apt-get update && sudo apt-get install -y make git && \
git clone git@github.com:corygabrielsen/dotfiles.git ~/code/dotfiles && \
cd ~/code/dotfiles && make
```

## Commands

```
make              Setup (default)
make require      Validate environment (read-only, fail-fast)
make doctor       Diagnose issues
make help         Show all targets
```

## What Gets Symlinked

```
~/.gitconfig      → git/gitconfig
~/.git-template   → git/git-template
~/.tmux.conf      → tmux/tmux.conf
~/.vim            → vim/vim
~/.vimrc          → vim/vimrc
~/.zshenv         → zsh/zshenv
~/.zprofile       → zsh/zprofile
~/.zshrc          → zsh/zshrc
~/.claude-env.sh  → claude/claude-env.sh
```

## Structure

```
dotfiles/
├── Makefile        # Setup orchestration
├── git/            # Git config, aliases, hooks
├── tmux/           # Tmux config
├── vim/            # Vim config + colorschemes
├── zsh/            # Zsh config (aliases, functions, env)
├── claude/         # Claude Code environment
├── apt-get/        # System package list
└── bin/            # Utility scripts
```

## Post-Setup

Set zsh as default shell:
```bash
chsh -s $(which zsh)
```
