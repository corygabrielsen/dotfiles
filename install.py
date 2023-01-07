#!/usr/bin/env python

import json
import os
from typing import Dict, List

HOME: str = os.environ["HOME"]
FOLDERS: Dict[str, List[str]] = json.load(open("folders.json"))


def get_dotfiles_root() -> str:
    """
    Returns the absolute path to the root of the dotfiles repo
    """
    # __file__ is a global variable that refers to the file containing the currently executing script
    path = os.path.abspath(os.path.join(__file__, ".."))

    # Use os.path.realpath to resolve any symlinks in the path
    return os.path.realpath(path)


DOTFILES_REPO_ROOT: str = get_dotfiles_root()

for folder, files in FOLDERS.items():
    for file in files:
        src: str = f"{DOTFILES_REPO_ROOT}/{folder}/{file}"
        dest: str = f"{HOME}/.{file}"

        try:
            os.unlink(dest)
        except FileNotFoundError:
            pass

        print(f"{src} -> {dest}")
        os.symlink(src, dest)
