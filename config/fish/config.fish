# Set environment variables early for performance
set -x XDG_SESSION_TYPE wayland
set -x SDL_VIDEODRIVER wayland
set -x CLUTTER_BACKEND wayland
set -x GTK_THEME 'Adwaita:dark'
set -x MOZ_ENABLE_WAYLAND 1
set -x EDITOR /usr/bin/nvim
set -x VISUAL /usr/bin/nvim
set -x _JAVA_AWT_WM_NONREPARENTING 1
set -x GDK_BACKEND wayland

# Optimize PATH settings (reduce multiple set calls)
set -x PATH "$HOME/.local/bin" "$HOME/bin" "$HOME/.local/bin/go/bin" "$HOME/.go/bin" "$HOME/.amplify/bin" "$HOME/.local/share/fnm" $PATH

# Initialize fnm and enable automatic version switching
if type -q fnm
    fnm env --use-on-cd | source
end

# Set up fnm command completions
if type -q fnm
    fnm completions --shell=fish | source
end

# Source global fish config if it exists
if test -f /etc/fish/config.fish
    source /etc/fish/config.fish
end

# Aliases (Fish uses functions)
function skg
    ssh -i $HOME/.ssh/id_rsa efpalaciosmo@34.139.160.76 $argv
end

function logs
    podman logs $argv
end

function copy_ssh
    scp -r efpalaciosmo@34.139.160.76:/home/$argv[1] $argv[2]
end

function tree_ex
    tree -f -I $argv[1] docker://docker.io/metnetd/$argv[2]
end

function ppush
    podman push $argv
end

function pb
    podman build $argv
end

function pi
    podman image $argv
end

function pc
    podman container $argv
end

function pp
    podman $argv[1] prune
end

# Key bindings
bind \t complete

# Starship prompt initialization (no unnecessary install check)
starship init fish | source
