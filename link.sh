#!/bin/bash
rm $HOME/.bashrc
ln -s $HOME/.dotfiles/bashrc $HOME/.bashrc
ln -s $HOME/.dotfiles/ssh $HOME/.ssh
ln -s $HOME/.dotfiles/config/bat $HOME/.config/bat
ln -s $HOME/.dotfiles/config/foot $HOME/.config/foot
ln -s $HOME/.dotfiles/config/nvim $HOME/.config/nvim
ln -s $HOME/.dotfiles/config/sway $HOME/.config/sway
ln -s $HOME/.dotfiles/config/tmux $HOME/.config/tmux
ln -s $HOME/.dotfiles/config/waybar $HOME/.config/waybar
ln -s $HOME/.dotfiles/config/wallpapers $HOME/.config/wallpapers
ln -s $HOME/.dotfiles/config/wofi $HOME/.config/wofi
ln -s $HOME/.dotfiles/config/zathura $HOME/.config/zathura
ln -s $HOME/.dotfiles/config/starship.toml $HOME/.config/starship.toml
ln -s $HOME/.dotfiles/config/electron25-flags.conf $HOME/.config/electron25-flags.conf