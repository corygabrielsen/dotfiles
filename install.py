#!/usr/bin/env python

import json
import os
from typing import Dict, List, Union, cast

COLOR_CODES = {
    "blue": "\033[0;34m",
    "bright_blue": "\033[38;5;39m",
    "bluewhite": "\033[38;5;159m",
    "soft_blue": "\033[38;5;66m",
    "green": "\033[38;5;40m",
    "purple": "\033[38;5;141m",
    "yellow": "\033[38;5;226m",
    "pale_blue": "\033[38;5;67m",
    "orange": "\033[38;5;214m",
    "pink": "\033[38;5;91m",
    "soft_pink": "\033[38;5;219m",
    "dark_grey": "\033[38;5;59m",
    "dark_gray": "\033[38;5;59m",
    "salmon": "\033[38;5;216m",
}
BLUE = COLOR_CODES["blue"]
BLUEWHITE = COLOR_CODES["bluewhite"]

HOME: str = os.path.expanduser("~")


class SubConfig:
    def __init__(self, colorize: str, files: List[str]):
        self.colorize: str = colorize
        self.files: List[str] = files


class Config:
    def __init__(self, config: Dict[str, SubConfig]):
        self.folders = config

    @property
    def ljust(self) -> int:
        """
        Returns the length of the longest dotfile file
        """
        maxlen: int = 0
        for dirname, folder_config in self.folders.items():
            for filename in folder_config.files:
                maxlen = max(maxlen, len(f".{filename}"))
        return maxlen

    def __iter__(self):
        return iter(self.folders.items())

    @staticmethod
    def load() -> "Config":
        """
        Loads the configuration data
        """
        schema = json.load(open("configuration-schema.json"))
        data: Dict[str, Dict[str, Union[str, List[str]]]] = json.load(
            open("configuration-data.json")
        )

        # Validate the configuration data against the schema
        try:
            import jsonschema  # type: ignore

            jsonschema.validate(instance=data, schema=schema)
        except ModuleNotFoundError:
            print("jsonschema module not found, skipping validation")

        parsed: Dict[str, SubConfig] = {}
        for folder, folder_config in data.items():
            parsed[folder] = SubConfig(
                colorize=str(folder_config["colorize"]),
                files=[f for f in folder_config["files"]],
            )

        return Config(parsed)


def get_dotfiles_root() -> str:
    """
    Returns the absolute path to the root of the dotfiles repo
    """
    # __file__ is a global variable that refers to the file containing the currently executing script
    path = os.path.abspath(os.path.join(__file__, ".."))

    # Use os.path.realpath to resolve any symlinks in the path
    return os.path.realpath(path)


DOTFILES_REPO_ROOT: str = get_dotfiles_root()


def print_shell_configuration() -> None:
    """
    Prints the shell configuration
    """
    # symbols
    BOPEN: str = f"{COLOR_CODES['yellow']}{{\033[0m"
    BCLOSE: str = f"{COLOR_CODES['yellow']}}}\033[0m"
    QUOTE: str = f"{COLOR_CODES['salmon']}\"\033[0m"
    DOLLAR = f"{BLUEWHITE}$\033[0m"

    # keywords
    EXPORT = f"{BLUE}export\033[0m"

    # variable substitutions
    VAR_PATH = f"{DOLLAR}{BOPEN}{BLUEWHITE}PATH\033[0m{BCLOSE}"
    VAR_DOTFILES_REPO_ROOT = (
        f"{DOLLAR}{BOPEN}{BLUEWHITE}DOTFILES_REPO_ROOT\033[0m{BCLOSE}"
    )

    # string literals
    dotfiles_repo_root_str_literal = f"{QUOTE}{DOTFILES_REPO_ROOT}\033[0m{QUOTE}"
    path_str_literal = f"{QUOTE}{VAR_PATH}:{VAR_DOTFILES_REPO_ROOT}/bin\033[0m{QUOTE}"

    # print the shell configuration
    print()
    print(f"## Shell configuration")
    print(f"{EXPORT} DOTFILES_REPO_ROOT={dotfiles_repo_root_str_literal}")
    print(f"{EXPORT} PATH={path_str_literal}")
    print()


def print_symlink(config: Config, color: str, target: str, file: str) -> None:
    """
    Prints a symlink
    """
    color_ansii_escape = f"{COLOR_CODES[color]}"
    dotfile_colorized = f"{color_ansii_escape}.{file.ljust(config.ljust)}\033[0m"


def create_symlinks(config: Config) -> None:
    """
    Creates the symlinks
    """
    for folder, folder_config in config.folders.items():
        for file in folder_config.files:
            src: str = f"{DOTFILES_REPO_ROOT}/{folder}/{file}"
            dest: str = f"{HOME}/.{file}"

            try:
                os.unlink(dest)
            except FileNotFoundError:
                pass
            os.symlink


def main() -> None:
    config: Config = Config.load()

    # Create symlinks
    print()
    print("## Symlinks")
    create_symlinks(config)

    for folder, folder_config in config:
        for file in folder_config.files:
            src: str = f"{DOTFILES_REPO_ROOT}/{folder}/{file}"
            dest: str = f"{HOME}/.{file}"

            try:
                os.unlink(dest)
            except FileNotFoundError:
                pass
            os.symlink(src, dest)

            ########################################
            color = folder_config.colorize
            color_ansii_escape = f"{COLOR_CODES[color]}"
            dotfile_colorized = (
                f"{color_ansii_escape}.{file.ljust(config.ljust)}\033[0m"
            )

            print_symlink(config, color, src, dest)
            ########################################

            rel_path = f"{folder}/{file}"
            rel_path_colorized = f"{color_ansii_escape}{rel_path}\033[0m"
            src_strip_rel_path = src.replace(f"{rel_path}", "")
            repo_dir = os.path.dirname(src_strip_rel_path)
            repo_dir_colorized = (
                f"{COLOR_CODES['pale_blue']}{os.path.basename(repo_dir)}/\033[0m"
            )

            repo_parent_dir = os.path.abspath(os.path.dirname(repo_dir))
            repo_parent_dir_colorized = (
                f"{COLOR_CODES['dark_grey']}{repo_parent_dir}/\033[0m"
            )
            # strip home directory from path
            repo_parent_dir_no_home = repo_parent_dir.replace(f"{HOME}/", "")
            repo_parent_dir_no_home_colorized = f"{repo_parent_dir_no_home}/"

            home_colorized = f"{COLOR_CODES['dark_grey']}{HOME}/\033[0m"
            print(
                f"{home_colorized}{dotfile_colorized} ---> {home_colorized}{repo_parent_dir_no_home_colorized}{repo_dir_colorized}{rel_path_colorized}"
            )

    # Print shell configuration
    # not neccessary yet but lots of effort to write the pretty colors so leaving it for now
    # print_shell_configuration()


if __name__ == "__main__":
    main()
