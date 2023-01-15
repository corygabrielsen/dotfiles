# Dotfiles

This repository contains my personal dotfiles and configurations for various
tools and applications.

## Contents

- `apt-get`: List of package dependencies.
- `git`: Git configuration files and hooks.
- `tmux`: TMUX configuration files.
- `vim`: Vim configuration files.
- `zsh`: Z shell configuration files.

## Installation

To install these dotfiles, clone the repository and run:

```bash
yarn install
yarn setup
```

This will install dependencies and create symlinks for the dotfiles in the repository,
linking them to the appropriate locations in your home directory.

### Fresh install
From a new computer, install git
```bash
sudo apt install -y git
```
Install npm
```bash
sudo apt install -y npm
```
Install yarn
```bash
sudo npm install -g yarn
```
Install zsh
```bash
sudo apt install -y zsh
chsh -s $(which zsh)
# logout / login
```

Then run the above instructions like normal.
# Customization

Feel free to use and customize these dotfiles as you see fit. If you make any
improvements or changes that you think would be useful to others, please
consider submitting a pull request.
