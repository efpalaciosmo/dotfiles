# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc


export XDG_CURRENT_DESKTOP=sway
export XDG_SESSION_DESKTOP=sway
export XDG_SESSION_TYPE=wayland
export SDL_VIDEODRIVER=wayland
export CLUTTER_BACKEND=wayland
export GTK_THEME='Adwaita:dark'
export MOZ_ENABLE_WAYLAND=1
export EDITOR=/usr/bin/nvim
export VISUAL=/usr/bin/nvim
export _JAVA_AWT_WM_NONREPARENTING=1
export GDK_BACKEND=wayland

export PATH="$HOME/.local/bin/go/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"


export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

alias skg="ssh -i $HOME/.ssh/id_rsa efpalaciosmo@34.139.160.76"
alias logs="podman logs $1"
alias copy_ssh="scp -r efpalaciosmo@34.139.160.76:/home/$1 $2"
# scp -r efpalaciosmo@34.139.160.76:/home/efpalaciosmo/HCEU_V3/ /home/efpalaciosmo/Desktop/metnet/direct/hceu/
# docker push imageID docker://docker.io/username/ImageName:tag
# podman login -u metnetd -p FZm@V8g}iHjsFK~ -v docker.io
# podman build -t lunia_python .
# podman push 00193de339ab docker://docker.io/metnetd/python_lunia:1.0.0
alias tree_ex="tree -f -I $1"
eval "$(starship init bash)"
