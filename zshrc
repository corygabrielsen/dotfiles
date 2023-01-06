#
# Options that enable or disable shell behavior:
#

# Save command history with timestamps and duration
setopt extended_history

# Incrementally add new history lines
setopt inc_append_history

# Expire duplicates first when history is full
setopt hist_expire_dups_first

# Verify history expansion rather than executing immediately
setopt hist_verify

# Share history between all instances of the shell
setopt share_history

# Don't automatically change directories when entering a directory name
unsetopt autocd

#
# Options that enable or disable shell prompts:
#

# Enable prompt string substitution
setopt PROMPT_SUBST

#
# Options that enable or disable shell features:
#

# Enable spelling correction for commands
# setopt correct

# Enable automatic cd to directories without typing "cd"
# setopt autocd

#
# Options that control the history file:
#

# Append new history lines rather than replacing existing ones
# setopt hist_append

# Append history immediately rather than waiting until the session is terminated
# setopt immediate_history

# Don't save command history with timestamps and duration
# unsetopt extended_history

# Don't incrementally add new history lines
# unsetopt inc_append_history

# Don't expire duplicates first when history is full
# unsetopt hist_expire_dups_first

# Execute history expansion immediately rather than verifying first
# unsetopt hist_verify

# Don't share history between instances of the shell
# unsetopt share_history

# Disable prompt string substitution
# unsetopt PROMPT_SUBST



#
# Configuring bindkey Utility
#

# Set default command line editing mode to vi
# set editing-mode vi

# Set default keymap to vi-command
# set keymap vi-command

# Set bindkey utility to operate in vi command mode
bindkey -v

# Set key binding for Ctrl-Y to yank (copy) rest of line in vi insert mode
# bindkey -M viins '^Y' vi-yank-eol

# Set key binding for Ctrl-L to clear screen
# bindkey '^L' clear-screen

# Set key binding for Ctrl-D to delete character under cursor
# bindkey '^D' delete-char

# Set key binding for Ctrl-W to delete previous word
# bindkey '^W' backward-kill-word

# Set key binding for Ctrl-R to perform incremental search backward through command history
bindkey '^R' history-incremental-search-backward

#
# Define colors
#

RED="\033[0;31m"
BRIGHT_RED="\033[1;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
YELLOWISH="\033[38;5;220m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
WHITE="\033[0;37m"
ENDC="\033[0m"
# 256 colors
# https://jonasjacek.github.io/colors/
ORANGE="\033[38;5;166m"
PURPLE="\033[38;5;141m"
PINK="\033[38;5;217m"
BROWN="\033[38;5;130m"
LIME="\033[38;5;154m"
BRIGHT_GREEN="\033[38;5;118m"
TURQUOISE="\033[38;5;45m"
LIGHT_BLUE="\033[38;5;39m"



# Display the current git branch
parse_git_branch() {
    local branch_name="$(git symbolic-ref HEAD 2>/dev/null | cut -d"/" -f 3)"
    if [ ! "$branch_name" ]; then
        local git_sha="$(git rev-parse --short HEAD)"
        echo "%{$BRIGHT_RED%}($git_sha)%{$ENDC%}"
    else
        if [ "$branch_name" = "master" ]; then
            echo "%{$MAGENTA%}($branch_name)%{$ENDC%}"
        else
            echo "%{$PURPLE%}($branch_name)%{$ENDC%}"
        fi
    fi
}

# Display information about any uncommitted changes in the current git repository
parse_git_changes() {
    local num_untracked_files="$(git ls-files --others --exclude-standard | wc -l)"
    local num_modified_files="$(git diff --name-only | wc -l)"
    local num_deleted_files="$(git diff --diff-filter=D --name-only | wc -l)"
    local num_added_files="$(git diff --cached --name-only | wc -l)"
    if [ "$num_added_files" -gt 0 ]; then
        echo -n "%{$BRIGHT_GREEN%}+$num_added_files%{$ENDC%}"
    fi
    if [ "$num_untracked_files" -gt 0 ]; then
        echo -n "%{$CYAN%}+$num_untracked_files%{$ENDC%}"
    fi
    if [ "$num_modified_files" -gt 0 ]; then
        echo -n "%{$YELLOWISH%}~$num_modified_files%{$ENDC%}"
    fi
}

# Display the current git branch and any uncommitted changes
parse_git() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        # We are not in a Git repository
        return
    fi
    local branch="$(parse_git_branch)"
    local changes="$(parse_git_changes)"
    if [ "$branch" ] || [ "$changes" ]; then
        echo -n " $branch$changes"
    fi
}

# Function to determine whether the current user is root
parse_command_prompt() {
  if [[ $EUID -eq 0 ]]; then
    # Root user
    echo "%{$BRIGHT_RED%}#%{$ENDC%}"
  else
    # Non-root user
    echo "%{$WHITE%}$%{$ENDC%}"
  fi
}

# Format the home directory for display in the prompt
format_homedir() {
    local dir="$PWD"
    local home="$HOME"
    local home_len=${#home}
    local dir_len=${#dir}
    if [[ "$dir" == "$home" ]]; then
        # Current working directory is home
        echo -n "%{$BLUE%}~%{$ENDC%}"
    elif [[ "$dir" == "$home/"* ]]; then
        # Current working directory is subdirectory of home
        echo -n "%{$LIME%}~%{$ENDC%}%{$TURQUOISE%}${dir:$home_len}%{$ENDC%}"
    else
        # Current working directory is outside of home
        echo -n "%{$ORANGE%}$dir%{$ENDC%}"
    fi
}

# Set the prompt
PS1='$(format_homedir)$(parse_git) $(parse_command_prompt) '




# Read local pre-zshrc, if present
if [ -f ~/.zshrc.local.before ]; then
  source ~/.zshrc.local.before
fi

# Read environment variables
if [ -f ~/.zsh.env ]; then
  source ~/.zsh.env
fi

# Read aliases
if [ -f ~/.aliases ]; then
  source ~/.aliases
fi

# Read custom functions
if [ -f ~/.zsh.functions ]; then
  source ~/.zsh.functions
fi

# Read ssh script
if [ -f ~/.zsh.ssh ]; then
  source ~/.zsh.ssh
fi

# Read local post-zshrc, if present
if [ -f ~/.zshrc.local.after ]; then
  source ~/.zshrc.local.after
fi