#!/bin/bash

# Potential Improvements:
# * Close switcher on lost focus
# * Override fzf options from outside

export CACHE_DIR=$HOME/.cache/jumpr
export APPS_CACHE=$CACHE_DIR/apps.list

function main() {
    list-all |
        search-prompt |
        process-selection
    clean-caches
}

function list-all() {
    list-windows | prefix-symbol ''
    list-commands | prefix-symbol ''

    if [[ ! -s "$APPS_CACHE" ]]; then
        mkdir -p "$CACHE_DIR"
        list-applications | tee "$APPS_CACHE"
    else
        cat "$APPS_CACHE"
    fi | prefix-symbol '󰣆'
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
        printf "app:%s\x1fapp: %s \033[90m# %s %s\033[0m\n" \
            "$id" "$name" "$id" "$keywords"
    done
}

function list-windows() {
    window-command List |
        sed 's/\\\"/\"/g' |
        sed "s/^(\(.*\),)$/\1/" |
        sed 's/^.\(.*\).$/\1/' |
        jq -r '
            .[] | 
                select(.wm_class != "jumpr") |
                "win:\(.id)\u001fwin: \(.title) \u001b[90m# \(.wm_class)\u001b[0m"
        ' |
        tac |
        {
            read -r first
            cat
            echo "$first"
        }
}

function list-commands() {
    printf "cmd:shutdown\x1fcmd: Shutdown\n"
    printf "cmd:restart\x1fcmd: Restart \033[90m# Reboot\033[0m\n"
    printf "cmd:logout\x1fcmd: Logout\n"
    printf "cmd:notifications\x1fcmd: Toggle notifications \033[90m# Do not disturb\033[0m\n"
}

function prefix-symbol() {
    while read -r in; do
        prefix "$(symbol "$1" "$in")" "$in"
    done
}

function prefix() {
    sep=$'\x1f'
    echo "${2//$sep/$sep$1 }"
}

function symbol() {
    case "${2,,}" in
    *firefox*) printf "\033[38;5;208m󰈹" ;;
    *teams*) printf "\033[38;5;135m󰊻" ;;
    *chrome* | *chromium*) printf "\033[38;5;33m" ;;
    *preferences*) printf "\033[38;5;75m" ;;
    *file*) printf "\033[38;5;178m" ;;
    *kitty* | *alacritty* | *console* | *terminal*) printf "\033[38;5;240m" ;;
    *nvim*) printf "\033[38;5;120m" ;;
    *telegram*) printf "\033[38;5;39m" ;;
    *slack*) printf "\033[38;5;99m󰒱" ;;
    *shutdown*) printf "\033[38;5;196m󰐥" ;;
    *restart*) printf "\033[38;5;196m󰜉" ;;
    *logout*) printf "\033[38;5;196m󰗽" ;;
    *notification*) printf "\033[38;5;214m󰂚" ;;
    *gnome*) printf "󰊬" ;;
    *libreoffice*) printf "\033[38;5;70m" ;;
    *vlc*) printf "\033[38;5;208m󰕼" ;;
    *pdf*) printf "\033[38;5;160m" ;;
    *) printf "\033[38;5;218m%s" "$1" ;;
    esac
    printf "\033[0m\n"
}

function search-prompt() {
    # TODO: setup on login
    # Theme
    export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS"
        --color='fg:#f2f4f8,bg:#161616,hl:#be95ff' \
        --color='fg+:#f2f4f8,bg+:#2a2a2a,hl+:#be95ff' \
        --color='info:#ff91c1,prompt:#ee5396,pointer:#f4a261' \
        --color='marker:#be95ff,spinner:#be95ff,header:#be95ff'"

    export -f close-window
    export -f window-command

    export -f list-all
    export -f list-windows
    export -f list-commands

    # Vim Bindings
    export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS"
        --bind 'start:unbind(j,k,i,D,G)' \
        --bind 'j:down,k:up,i:show-input+unbind(j,k,i,D,G),D:execute-silent(close-window {1})+reload(list-all),G:first' \
        --bind 'esc,ctrl-c:transform:
          if [[ \$FZF_INPUT_STATE = enabled ]]; then
            echo \"rebind(j,k,i,D,G)+hide-input\"
          else
            echo abort
          fi
        '"

    fzf --accept-nth=1 -d $'\x1f' --with-nth=2 \
        --tiebreak=index \
        --header "Gnome Jumper" --header-first \
        --ansi --highlight-line --no-hscroll
}

function close-window() {
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
