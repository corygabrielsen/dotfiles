#!/usr/bin/env node

import * as fs from "fs";
import * as path from "path";

interface Folders {
  [folder: string]: string[];
}

function getDotfilesRoot(): string {
  return fs.realpathSync(path.resolve(__dirname));
}

const FOLDERS: Folders = {
  git: ["gitconfig", "git-template"],
  tmux: ["tmux.conf"],
  vim: ["vim", "vimrc"],
  zsh: ["zshenv", "zprofile", "zshrc"],
};

const HOME = process.env.HOME;
if (!HOME) throw new Error("Environment variable HOME not set");

const DOTFILES_REPO_ROOT = getDotfilesRoot();

for (const [folder, files] of Object.entries(FOLDERS)) {
  for (const file of files) {
    const src = path.join(DOTFILES_REPO_ROOT, folder, file);
    const dest = path.join(HOME, `.${file}`);

    try {
      fs.unlinkSync(dest);
    } catch {
      // do nothing
    }

    console.log(`${src} -> ${dest}`);
    fs.symlinkSync(src, dest);
  }
}
