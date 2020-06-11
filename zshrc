
# Read local pre-zshrc, if present
if [ -f ~/.zshrc.local.before ]; then
  source ~/.zshrc.local.before
fi

# Read Oh-My-Zsh
if [ -f ~/.zsh.oh-my-zsh ]; then
  source ~/.zsh.oh-my-zsh
fi

if [ -f ~/.zsh.setopt ]; then
    source ~/.zsh.setopt
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

