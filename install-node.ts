#!/usr/bin/env node

import * as fs from "fs";
import * as path from "path";

interface Folders {
  [folder: string]: string[];
}

const HOME: string =
  process.env.HOME ||
  (() => {
    throw new Error("Environment variable HOME not set");
  })();
const FOLDERS: Folders = JSON.parse(fs.readFileSync("folders.json", "utf8"));

const DOTFILES_REPO_ROOT = fs.realpathSync(path.resolve(__dirname));

for (const [folder, files] of Object.entries(FOLDERS)) {
  for (const file of files) {
    const src = path.join(DOTFILES_REPO_ROOT, folder, file);
    const dest = path.join(HOME, `.${file}`);

    try {
      fs.unlinkSync(dest);
    } catch {
      // do nothing
    }

    console.log(`${dest.padEnd(23)} ---> ${src}`);
    fs.symlinkSync(src, dest);
  }
}
