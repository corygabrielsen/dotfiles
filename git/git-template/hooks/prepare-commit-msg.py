#!/usr/bin/env python3


"""
This is a pre-commit-msg hook that uses the OpenAI API to get a suggested commit message
for the diff that is about to be committed.

To use this hook, you will need to:
- Set the OPENAI_API_KEY environment variable to your OpenAI API key.

To symlink this file into your git repo, run the following command:
ln -s /path/to/git/git-template/hooks/prepare-commit-msg.py .git/hooks/prepare-commit-msg

This hook is invoked by Git just before the commit message editor is launched,
and it is passed the name of the file that holds the commit message.
The hook should edit this file in place and then exit.
If the hook exits non-zero, Git aborts the commit process.
"""


import os
import subprocess
import sys


# a very robust function to check if we are inside the root of the potpourri repo
# but don't rely on filenames, instead check for the existence of a file that is
# expected to be in the root of the repo
#
# A safe way to do this is to check if there is a README file that is in the root
# and the first line of README should be "# potpourri"
#
# That will be sufficient to check if we are in the root of the source code repo
def is_dotfiles_repo_root(dirname: str) -> bool:
    readme_file = os.path.join(dirname, "README.md")
    if not os.path.exists(readme_file):
        return False

    matches = False
    with open(readme_file, "r") as f:
        first_line = f.readline()
        matches = first_line.lower().strip() == "# Dotfiles".lower()

    return matches


# find git repo root by recursively searching until the current folder contains a .git folder
def find_repo_root(path: str) -> str:
    dirname = os.path.abspath(os.path.dirname(__file__))

    # should be named "hooks"
    assert (
        os.path.basename(dirname) == "hooks"
    ), f"__file__={__file__} is not in a directory named hooks"

    # up one more
    dirname = os.path.abspath(os.path.join(dirname, os.pardir))

    # should be named ".git" if ran under symlink
    # that is, we expect that we are inside .git/hooks
    #
    # in the repository, the file lives at /git/git-template/hooks/prepare-commit-msg.py
    assert (
        os.path.basename(dirname) == ".git"
        or os.path.basename(dirname) == "git-template"
    ), f"__file__={__file__} is not in a directory named .git or git-template"

    # now we can just keep going up until we find the root of the repo
    while not is_dotfiles_repo_root(dirname) and not dirname == "/":
        dirname = os.path.abspath(os.path.join(dirname, os.pardir))

    if dirname == "/":
        error_msg = f"Could not find the root of the repo to import potpourri.python.openai. __file__={__file__}"
        raise Exception(error_msg)

    return dirname


def add_repo_root_to_pythonpath(log=False) -> None:
    # the script depends on the potpourri python package located in the repo root
    repo_root = find_repo_root(__file__)

    # ensure potpourri/ submodule exists and is checked out
    potpourri_submodule = os.path.join(repo_root, "potpourri")
    assert os.path.exists(
        potpourri_submodule
    ), f"Expected {potpourri_submodule} to exist. Did you forget to run `git submodule update --init --recursive`?"

    # ensure expected file structure for easier debugging
    potpourri_python = os.path.join(potpourri_submodule, "python")
    assert os.path.exists(
        potpourri_submodule
    ), f"Expected {potpourri_python} to exist. Did the directory structure change?"

    potpourri_python_openai = os.path.join(potpourri_python, "openai")
    assert os.path.exists(
        potpourri_python_openai
    ), f"Expected {potpourri_python_openai} to exist. Did the directory structure change?"

    # add the repo root to the python path so we can import the potpourri python package
    sys.path.append(repo_root)


add_repo_root_to_pythonpath()
from potpourri.python.openai.client import OpenAIApiClient  # noqa: E402
from potpourri.python.openai.commit_message import CommitMessage  # noqa: E402


def get_prompt(model: str, status_text: str, diff_text: str) -> str:
    return f"""
I want you to act as a technical writer for software engineers, your
primary responsibility is to write clear and concise commit messages
for code changes. Your job is to communicate the purpose and impact
of code changes to other members of the development team.

A good commit message has the following characteristics:
- It is concise and accurate.
- It is written in the imperative mood and begins with a verb
- It explains why the change was made, rather than how it was made.
- It includes a signature at the end of the message.

Here is an example of a good commit message:
```
🤖 Ensure non-empty password during login

The login form was submitting even if the password field was empty.
This commit fixes the bug by checking that the password field is not
empty before allowing the form to be submitted.


(commit message written by OpenAI {model})
```

Here is an example of a good commit message:
```text
🤖 Include latest dependencies for eslint, prettier

Updates the package.json file to include the latest
dependencies for prettier and eslint for code formatting.

prettier is a code formatter that automatically formats code to
conform to a consistent style. It is configured to use the
recommended settings for the JavaScript Standard Style.

eslint is a linter that checks for common errors and code smells.
It is configured to use the recommended settings for the
JavaScript Standard Style.


(commit message written by OpenAI {model})
```

Some other tips for writing good commit messages:
- Begin with "🤖 "
- Keep the subject line (the first line) to 50 characters or less
- Separate subject from body with a blank line
- Use the body of the message to explain the details of the commit
- Wrap the body at 72 characters                              like this
- Avoid words like "Update", "Refactor", "Fix", "Add", "Remove" in the
    subject line

At the end of the commit message, add two blank lines followed by a
signature:
```text
(commit message written by OpenAI {model})
```

Your first task is to review staged changes and suggest a commit
message for the latest patch.

Files changed:
```
// git status -s
{status_text}
```

Files diff:
```diff
// git diff --cached --no-color --no-ext-diff --unified=0 --no-prefix
{diff_text}
```

Choose a unique and stylish first line in the imperative tense
that concisely describes the changes made in the commit.
This line should be no more than 50 characters.

Now, please write a suggested commit message below that is clear,
concise, and colorful, following the rules described above,
beginning with "🤖 " and ending with the signature
"(commit message written by OpenAI {model})":

Respond with:
- A detailed paragraph explaining WHY the changes were made
- Ten unique, stylish, colorful, and concise subject lines
- A suggested commit message enclosed in ```text ... ```

Detailed explanation:
"""


def is_exists_empty_file(path: str) -> bool:
    # Check if the commit message file does not exist
    if not os.path.exists(sys.argv[1]):
        print(f"Commit message file does not exist: {sys.argv[1]}")
        return False

    # Check if the commit message file is not empty
    with open(sys.argv[1], "r") as f:
        if f.readline().strip():
            print(f"Commit message file is not empty: {sys.argv[1]}")
            return False

    # Commit message file exists and is empty
    return True


def check_abort() -> None:
    """
    Check if the commit message file is not empty or if the OPENAI_API_KEY environment variable is not set.

    If the commit message file is not empty, print a message and exit.
    If the OPENAI_API_KEY environment variable is not set, print an error message in red and exit.
    """
    if not is_exists_empty_file(sys.argv[1]):
        # Commit message already specified earlier in the commit process
        exit(0)

    # Check if the OPENAI_API_KEY environment variable is not set
    if "OPENAI_API_KEY" not in os.environ:
        # Print an error message in red
        print("\033[0;31mOpenAI suggestion failed: OPENAI_API_KEY not set\033[0m")
        exit(1)


def get_status_text() -> str:
    """
    Get the status text for the staged changes in the current Git repository.

    The `--short` option tells `git status` to output the status in a shorter format.
    The `--untracked-files=no` option tells `git status` to ignore untracked files.
    Together, these options limit the output of `git status` to only report files which are staged for commit.

    Returns:
    str: The status text for the staged changes in the current Git repository.
    """
    # Get the status text for the staged changes in the current Git repository
    result: subprocess.CompletedProcess = subprocess.run(
        ["git", "status", "--short", "--untracked-files=no"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        encoding="utf-8",
    )
    if result.stderr:
        print("\033[0;31m", result.stderr, "\033[0m")
    if result.returncode != 0:
        raise Exception("git diff failed")

    return result.stdout


def get_diff_text(excluded=["package-lock.json", "yarn.lock"]) -> str:
    """
    Get the diff text for the staged changes in the current Git repository.

    Returns:
    str: The diff text for the staged changes in the current Git
        repository, with a maximum length of 10000 characters.
    """
    # Find the filenames of the staged changes in the current Git
    # repository, excluding package-lock.json and yarn.lock
    # diff-filter=ACMRTUXB means: Added (A), Copied (C), Modified (M),
    # Renamed (R), Changed (T), Updated but unmerged (U), eXisting (X),
    # Broken (B)
    result: subprocess.CompletedProcess = subprocess.run(
        ["git", "diff", "--cached", "--name-only", "--diff-filter=ACMRTUXB"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        encoding="utf-8",
    )
    if result.stderr:
        print("\033[0;31m", result.stderr, "\033[0m")
    if result.returncode != 0:
        raise Exception("git diff failed")

    # Get the diff text for the staged changes in the current Git repository
    staged_changes = [
        filename for filename in result.stdout.splitlines() if filename not in excluded
    ]
    args = [
        "git",
        "diff",
        "--cached",
        "--no-color",
        "--no-ext-diff",
        "--unified=0",
        "--no-prefix",
    ] + staged_changes
    result = subprocess.run(
        args,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        encoding="utf-8",
    )
    if result.stderr:
        print("\033[0;31m", result.stderr, "\033[0m")
    if result.returncode != 0:
        raise Exception("git diff failed")

    # the output may be too long so we will take the first 10000 characters
    LIMIT = 9000
    output = result.stdout
    if len(output) > LIMIT:
        output = output[:LIMIT] + "\n...(truncated)"
    return output


def main() -> None:
    """
    Use the OpenAI API to get a suggested commit message for the diff that is about to be committed.
    """
    # Check if the commit should be aborted
    check_abort()

    # Get the status text and diff text for the staged changes in the
    # current Git repository
    git_status_text: str = get_status_text()
    git_diff_text: str = get_diff_text()

    model: str = "text-davinci-003"

    # Get the prompt
    prompt: str = get_prompt(
        model=model, status_text=git_status_text, diff_text=git_diff_text
    )
    # save prompt to debug file
    with open(".prompt", "w") as f:
        f.write(prompt)

    # Get the suggested commit message
    print("Getting suggested commit message...")
    suggested_commit_message: CommitMessage = (
        OpenAIApiClient().get_suggested_commit_message(prompt=prompt, model=model)
    )
    # delete the commit message file
    os.remove(sys.argv[1])

    # directly run gitf  commit -m "suggested_commit_message"
    # write commit message to file
    with open(sys.argv[1], "w") as f:
        f.write(suggested_commit_message.text)

    print()
    print(f"Wrote suggested commit message to {sys.argv[1]}")
    print()
    for line in suggested_commit_message.text.splitlines():
        # color code \033[0;90m
        print(f"> \033[0;90m{line}\033[0m")
    print()


if __name__ == "__main__":
    """
    Run the main function.
    """
    main()
