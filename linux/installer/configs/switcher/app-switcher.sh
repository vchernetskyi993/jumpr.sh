#!/bin/bash

function main() {
    list-all |
        fzf --accept-nth=1 -d ',' --with-nth=2 --tiebreak=index |
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

    # Use find to list all .desktop files, remove suffix & duplicates
    echo "$all_dirs" | tr ':' '\n' | while read -r dir; do
        find "$dir/applications" -type f -name '*.desktop' \
            -exec basename {} .desktop \; 2>/dev/null
    done | sort -u | while read -r app; do
        echo "app:${app},app: ${app}"
    done
}

function list-windows() {
    gdbus call --session \
        --dest org.gnome.Shell \
        --object-path /org/gnome/Shell/Extensions/Windows \
        --method org.gnome.Shell.Extensions.Windows.List |
        sed "s/^('\(.*\)',)$/\1/" |
        jq -r '.[] | select(.title != "app-switcher") | "win:\(.id),win: [\(.wm_class)] \(.title)"'
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
        gtk-launch "$appid"
        ;;
    esac
}

[[ "${BASH_SOURCE[0]}" != "${0}" ]] || main $@
