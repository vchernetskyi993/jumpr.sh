#!/bin/bash

# Potential Improvements:
# * Close switcher on lost focus
# * Create custom icon
# * Icons for applications and windows

export CACHE_DIR=$HOME/.cache/app-switcher
export APPS_CACHE=$CACHE_DIR/apps.list

function main() {
    list-all |
        search-prompt |
        process-selection
    clean-caches
}

function list-all() {
    list-windows
    list-commands

    if [[ ! -s "$APPS_CACHE" ]]; then
        mkdir -p "$CACHE_DIR"
        list-applications | tee "$APPS_CACHE"
    else
        cat "$APPS_CACHE"
    fi
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
    echo "Retrieving windows" >>/tmp/app-switcher-log.txt
    window-command List |
        sed 's/\\\"/\"/g' |
        sed "s/^(\(.*\),)$/\1/" |
        sed 's/^.\(.*\).$/\1/' |
        jq -r '.[] | select(.wm_class != "app-switcher") | "win:\(.id),win: [ \(.wm_class) ] \(.title)"' |
        tac | {
        read -r first
        cat
        echo "$first"
    }
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

    export -f close-window
    export -f window-command

    export -f list-all
    export -f list-windows
    export -f list-commands

    # Vim Bindings
    export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS"
        --bind 'start:unbind(j,k,i,D)' \
        --bind 'j:down,k:up,i:show-input+unbind(j,k,i,D),D:execute-silent(close-window {1})+reload(list-all)' \
        --bind 'esc,ctrl-c:transform:
          if [[ \$FZF_INPUT_STATE = enabled ]]; then
            echo \"rebind(j,k,i,D)+hide-input\"
          else
            echo abort
          fi
        '"

    fzf --accept-nth=1 -d ',' --with-nth=2 \
        --tiebreak=index \
        --header "App Switcher" --header-first \
        --ansi
}

function close-window() {
    echo "Closing window '${1}'" >>/tmp/app-switcher-log.txt
    if [[ "${1}" == win:* ]]; then
        winid="${1#win:}"
        window-command Close "$winid"
        while window-command Details "$winid"; do
            sleep 0.05
        done
    fi
}

function process-selection() {
    local sel
    read -r sel

    if [[ -z "$sel" ]]; then
        return
    fi

    case "$sel" in
    win:*)
        winid="${sel#win:}"
        window-command Activate "$winid"
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

function window-command() {
    local method=$1
    shift
    gdbus call --session \
        --dest org.gnome.Shell \
        --object-path /org/gnome/Shell/Extensions/Windows \
        --method org.gnome.Shell.Extensions.Windows."$method" "$@"
}

function clean-caches() {
    rm "$APPS_CACHE"
}

[[ "${BASH_SOURCE[0]}" != "${0}" ]] || main "$@"
