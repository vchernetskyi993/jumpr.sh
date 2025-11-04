#!/bin/bash

# Potential Improvements:
# * Close window from switcher
# * Close switcher on lost focus
# * Create custom icon

function main() {
    list-all |
        search-prompt |
        focus-window
}

function list-all() {
    list-windows
    list-applications
    list-commands
}

function list-applications() {
    local data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
    local data_dirs="${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
    local all_dirs="$data_home:$data_dirs"

    echo "$all_dirs" | tr ':' '\n' | while read -r dir; do
        find "$dir/applications" -type f -name '*.desktop'
    done | awk -F/ '!seen[$NF]++' | while read -r desktop; do
        id=$(basename -s .desktop "$desktop")
        name=$(grep -m1 '^Name=' "$desktop" | cut -d= -f2-)
        keywords=$(grep -m1 '^Keywords=' "$desktop" | cut -d= -f2-)
        printf "app:%s,app: [ %s ] %s%b\n" \
            "$id" "$id" "$name" \
            "${keywords:+ \033[90m# ${keywords}\033[0m}"
    done
}

function list-windows() {
    gdbus call --session \
        --dest org.gnome.Shell \
        --object-path /org/gnome/Shell/Extensions/Windows \
        --method org.gnome.Shell.Extensions.Windows.List |
        sed 's/\\\"/\"/g' |
        sed "s/^(\(.*\),)$/\1/" |
        sed 's/^.\(.*\).$/\1/' |
        jq -r '.[] | select(.wm_class != "app-switcher") | "win:\(.id),win: [ \(.wm_class) ] \(.title)"' |
        tac |
        tail -n +2
}

function list-commands() {
    printf "cmd:shutdown,cmd: Shutdown\n"
    printf "cmd:restart,cmd: Restart \033[90m# Reboot\033[0m\n"
    printf "cmd:logout,cmd: Logout\n"
    printf "cmd:notifications,cmd: Toggle notifications \033[90m# Do not disturb\033[0m\n"
}

function search-prompt() {
    # TODO: setup on login
    # Theme
    export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS"
        --color='fg:#f2f4f8,bg:#161616,hl:#6e6f70' \
        --color='fg+:#f2f4f8,bg+:#2a2a2a,hl+:#be95ff' \
        --color='info:#ff91c1,prompt:#ee5396,pointer:#f4a261' \
        --color='marker:#be95ff,spinner:#be95ff,header:#6e6f70'"

    # Vim Bindings
    export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS"
        --bind 'start:unbind(j,k,i)' \
        --bind 'j:down,k:up,i:show-input+unbind(j,k,i)' \
        --bind 'esc,ctrl-c:transform:
          if [[ \$FZF_INPUT_STATE = enabled ]]; then
            echo \"rebind(j,k,i)+hide-input\"
          else
            echo abort
          fi
        '"

    fzf --accept-nth=1 -d ',' --with-nth=2 \
        --tiebreak=index \
        --header "App Switcher" --header-first \
        --ansi
}

function focus-window() {
    local sel
    read -r sel

    if [[ -z "$sel" ]]; then
        return
    fi

    case "$sel" in
    win:*)
        winid="${sel#win:}"
        gdbus call --session \
            --dest org.gnome.Shell \
            --object-path /org/gnome/Shell/Extensions/Windows \
            --method org.gnome.Shell.Extensions.Windows.Activate "$winid"
        ;;
    app:*)
        appid="${sel#app:}"
        setsid nohup gtk-launch "$appid" >/dev/null 2>&1
        ;;
    cmd:*)
        cmd="${sel#cmd:}"
        case "$cmd" in
        shutdown)
            systemctl poweroff
            ;;
        restart)
            systemctl reboot
            ;;
        logout)
            gnome-session-quit --logout --no-prompt
            ;;
        notifications)
            if [ "$(gsettings get org.gnome.desktop.notifications show-banners)" = "true" ]; then
                gsettings set org.gnome.desktop.notifications show-banners false
            else
                gsettings set org.gnome.desktop.notifications show-banners true
            fi
            ;;
        esac
        ;;
    esac
}

[[ "${BASH_SOURCE[0]}" != "${0}" ]] || main $@
