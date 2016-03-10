#!/bin/bash

dir="/home/corygabr/dev/dotfiles"
files=(aliases gitconfig git-template vim vimrc zsh.env zsh.functions zsh.oh-my-zsh zsh.setopt zsh.ssh zshrc)

# Verify all files exist
echo "Validating setup context..."
for file in "${files[@]}"; do
    if [ -f $file ]; then
        echo "Preparing to link file $file"
    elif [ -d $file ]; then
        echo "Preparing to link directory $file"
    else
        echo "$file does not exist. $file is expected."
        exit 1
    fi
done
echo

timestamp=`date +%s%3N`
echo "Current millis since epoch: $timestamp"
echo

for file in "${files[@]}"; do
    echo "Setting up $file..."
    if [ -e ~/.$file ]; then
        echo "File ~/.$file already exists"
        echo "Moving ~/.$file to ~/.$file.bak-$timestamp"
        mv ~/.$file ~/.$file.bak-$timestamp
    elif [ -d ~/.$file ]; then
        echo "Directory ~/.$file already exists"
        echo "Moving ~/.$file to ~/.$file.bak-$timestamp"
        mv ~/.$file ~/.$file.bak-$timestamp
    else
        echo "~/.$file does not exist"
    fi
    echo "Linking ~/.$file to $dir/$file"
    ln -s $dir/$file ~/.$file
    echo
done
