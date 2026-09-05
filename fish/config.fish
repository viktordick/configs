if test -r /etc/locale.conf
    while read -l kv
        set -gx (string split "=" -- $kv)
    end </etc/locale.conf
end

set -gx PATH $PATH ~/bin
set -gx EDITOR nvim

set -gx SSH_AUTH_SOCK $XDG_RUNTIME_DIR/keyring/ssh

eval (dircolors ~/.dir_colors/dircolors | head -n 1 | sed 's/^LS_COLORS=/set -x LS_COLORS /;s/;$//')
