#!/bin/bash

# Potential Improvements:
# * Close window from switcher
# * Use for common system actions:
#   * Shut down
#   * Reboot
#   * Logout
#   * Do not disturb
# * Close switcher on lost focus
# * Create custom icon
# * Search launchers by keywords and name
#   * Make keywords visible but "greyed out"

function main() {
    list-all |
        search-prompt |
        focus-window
}

function list-all() {
    list-windows
    list-applications
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
    local id
    read -r id

    if [[ -z "$id" ]]; then
        return
    fi

    case "$id" in
    win:*)
        winid="${id#win:}"
        gdbus call --session \
            --dest org.gnome.Shell \
            --object-path /org/gnome/Shell/Extensions/Windows \
            --method org.gnome.Shell.Extensions.Windows.Activate "$winid"
        ;;
    app:*)
        appid="${id#app:}"
        setsid nohup gtk-launch "$appid" >/dev/null 2>&1
        ;;
    esac
}

[[ "${BASH_SOURCE[0]}" != "${0}" ]] || main $@
