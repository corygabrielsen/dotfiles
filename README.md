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
cd $DIR/dotfiles && \
yarn install && \
yarn setup
```

This will install dependencies and create symlinks for the dotfiles in the repository,
linking them to the appropriate locations in your home directory.

### One-liner

```bash
(
    DIR=$HOME/code;

    prompt() { echo -e "\x1b[32m$1\x1b[0m"; sleep 1; echo -n "."; sleep 1; echo -n "."; sleep 1; echo -n "."; sleep 1; echo; }

    install_base() {
        sudo apt-get update && sudo apt-get install -y curl git zsh;
        curl --version && git --version && zsh --version;
    }

    install_nvm() {
        curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash;
        export NVM_DIR="$HOME/.nvm";
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh";
    }

    install_node() {
        nvm install 20 && nvm use 20;
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh";
        echo "npm $(npm --version)"; echo "node $(node --version)";
    }

    install_yarn() { npm install -g yarn; }

    clone_dotfiles() {
        mkdir -p $DIR && cd $DIR;
        git clone --recursive git@github.com:stoooops/dotfiles.git && cd dotfiles;
    }

    run_setup() {
        yarn install && yarn setup;
        chsh -s $(which zsh);
        echo -e "\x1b[32mDone\x1b[0m";
    }

    [ -d "$DIR/dotfiles" ] && prompt "$DIR/dotfiles already exists" && exit 0 || true;

    prompt "Installing curl, git, zsh" && install_base && \
    prompt "Installing NVM" && install_nvm && \
    prompt "Installing Node.js v20" && install_node && \
    prompt "Installing yarn" && install_yarn && \
    prompt "Cloning dotfiles" && clone_dotfiles && \
    prompt "Installing dependencies and running setup" && run_setup
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

- install `nvm`

  ```bash
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash;
  export NVM_DIR="$HOME/.nvm";
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh";
  ```

- install `node`

  ```bash
  nvm install 20 && nvm use 20;
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh";
  echo "npm $(npm --version)"; echo "node $(node --version)";
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
