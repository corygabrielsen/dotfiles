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
DIR=$HOME/code && \
mkdir -p $DIR && \
cd $DIR && \
git clone --recursive git@github.com:stoooops/dotfiles.git && \
yarn install && \
yarn setup
```

This will install dependencies and create symlinks for the dotfiles in the repository,
linking them to the appropriate locations in your home directory.

### One-liner

```bash
(
    DIR=$HOME/code && \
    [ -d "$DIR/dotfiles" ] && echo -e "\x1b[32m$DIR/dotfiles already exists\x1b[0m" && exit 0 || true;
    prompt() {
        echo -e "\x1b[32m$1\x1b[0m"
        sleep 1; echo -n "."; sleep 1; echo -n "."; sleep 1; echo -n "."; sleep 1; echo
    };
    sudo apt-get update && \
    prompt "Installing curl, git, zsh" && \
    sudo apt-get install -y curl git zsh && \
    curl --version && \
    git --version && \
    zsh --version && \
    NODE_VERSION=18 && \
    prompt "Installing nodejs v${NODE_VERSION}" && \
    (test -x "$(command -v npm)" && node -v | grep -q "v${NODE_VERSION}" && exit 0) || \
    (
        (
            (test -x "$(command -v npm)" && sudo apt-get remove nodejs) || true
        ) && \
        curl -s "https://deb.nodesource.com/setup_${NODE_VERSION}.x" | sudo bash && \
        sudo apt install $Y nodejs
    ) && \
    echo "npm  $(npm --version)" && \
    echo "node $(node --version)" && \
    prompt "Installing yarn" && \
    sudo npm install -g yarn && \
    prompt "Cloning dotfiles" && \
    mkdir -p $DIR && \
    cd $DIR && \
    git clone --recursive git@github.com:stoooops/dotfiles.git && \
    cd dotfiles && \
    prompt "Installing dependencies" && \
    yarn install && \
    prompt "Running setup" && \
    yarn setup && \
    prompt "Setting zsh as default shell" && \
    chsh -s $(which zsh) && \
    echo -e "\x1b[32mDone\x1b[0m"
)
```

### Fresh install

From a new computer:

- install `curl`

  ```bash
  sudo apt-get install -y curl
  ```

- install `git`

  ```bash
  sudo apt-get install -y git
  ```

- install `zsh`

  ```bash
  sudo apt-get install -y zsh
  ```

- install `node` v18

  1. `if` _npm is installed && nodejs == v18_ `then` do nothing
  2. `else if` _npm is installed && nodejs != v18_ `then` remove it and install nodejs 16
  3. `else` _npm is not installed_, install nodejs 18

  ```bash
  NODE_VERSION=18 && \
  prompt "Installing nodejs v${NODE_VERSION}" && \
  (test -x "$(command -v npm)" && node -v | grep -q "v${NODE_VERSION}" && exit 0) || \
  (
      (
          (test -x "$(command -v npm)" && sudo apt-get remove nodejs) || true
      ) && \
      curl -s "https://deb.nodesource.com/setup_${NODE_VERSION}.x" | sudo bash && \
      sudo apt install $Y nodejs
  ) && \
  npm --version && \
  node --version
  ```

- install yarn

  ```bash
  sudo npm install -g yarn
  ```

- Install dotfiles

  1. clone repo
  2. install dependencies
  3. run setup
  4. set zsh as default shell

  ```bash
  DIR=$HOME/code &&
  mkdir -p $DIR && \
  cd $DIR && \
  git clone --recursive git@github.com:stoooops/dotfiles.git && \
  cd dotfiles && \
  yarn install && \
  yarn setup && \
  chsh -s $(which zsh)
  ```
