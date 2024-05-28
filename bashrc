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


export XDG_SESSION_TYPE=wayland
export SDL_VIDEODRIVER=wayland
export CLUTTER_BACKEND=wayland
export GTK_THEME='Adwaita:dark'
export MOZ_ENABLE_WAYLAND=1
export EDITOR=/usr/bin/nvim
export VISUAL=/usr/bin/nvim
export _JAVA_AWT_WM_NONREPARENTING=1
export GDK_BACKEND=wayland
export DOCKER_HOST=unix:///run/user/1000/podman/podman.sock
export PATH="$HOME/.local/bin/go/bin:$PATH"
export PATH="$HOME/.go/bin:$PATH"



alias skg="ssh -i $HOME/.ssh/id_rsa efpalaciosmo@34.139.160.76"
alias logs="podman logs $1"
alias copy_ssh="scp -r efpalaciosmo@34.139.160.76:/home/$1 $2"
# scp -r efpalaciosmo@34.139.160.76:/home/efpalaciosmo/HCEU_V3/ /home/efpalaciosmo/Desktop/metnet/direct/hceu/
# docker push imageID docker://docker.io/username/ImageName:tag
alias tree_ex="tree -f -I $1 docker://docker.io/metnetd/$2"
alias plogin="podman login -u metnetd -p FZm@V8g}iHjsFK~ -v docker.io"
alias ppush="podman push $1"
alias pb="podman build"
alias pi="podman image"
alias pc="podman container"
pp(){
    podman $1 prune
}

# fnm
export PATH="/var/home/efpalaciosmo/Desktop/work/.local/share/fnm:$PATH"
eval "`fnm env`"

bind 'set show-all-if-ambiguous on'
bind 'TAB:menu-complete'
eval "$(starship init bash)"