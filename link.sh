#!/bin/bash

# Setup github
git config --global init.defaultBranch main
git config --global user.name "Efrain Palacios Mosquera"
git config --global user.email "efpalaciosmo@unal.edu.co"


# Setup links
rm $HOME/.bashrc
ln -s $HOME/.dotfiles/bashrc $HOME/.bashrc
ln -s $HOME/.dotfiles/ssh $HOME/.ssh
ln -s $HOME/.dotfiles/config/bat $HOME/.config/bat
ln -s $HOME/.dotfiles/config/nvim $HOME/.config/nvim
ln -s $HOME/.dotfiles/config/tmux $HOME/.config/tmux
ln -s $HOME/.dotfiles/config/kitty $HOME/.config/kitty
ln -s $HOME/.dotfiles/config/starship.toml $HOME/.config/starship.toml
ln -s $HOME/.dotfiles/config/electron25-flags.conf $HOME/.config/electron25-flags.conf

#unlink $HOME/.bashrc 
#unlink $HOME/.ssh
#unlink $HOME/.config/bat
#unlink $HOME/.config/nvim
#unlink $HOME/.config/tmux
#unlink $HOME/.config/kitty
#unlink $HOME/.config/starship.toml
#unlink $HOME/.config/electron25-flags.conf