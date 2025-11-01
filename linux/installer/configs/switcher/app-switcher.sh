#!/bin/bash

# Dependencies:
# * fzf
# * window-calls@domandoman.xyz

function main() {
    list-windows |
        fzf --accept-nth=1 -d ',' --with-nth=2 |
        focus-window
}

function list-windows() {
    gdbus call --session \
        --dest org.gnome.Shell \
        --object-path /org/gnome/Shell/Extensions/Windows \
        --method org.gnome.Shell.Extensions.Windows.List |
        sed "s/^('\(.*\)',)$/\1/" |
        jq -r '.[] | "\(.id),window: [\(.wm_class)] \(.title)"'
}

function focus-window() {
    local winid
    read -r winid

    if [[ -z "$winid" ]]; then
        return
    fi

    gdbus call --session \
        --dest org.gnome.Shell \
        --object-path /org/gnome/Shell/Extensions/Windows \
        --method org.gnome.Shell.Extensions.Windows.Activate "$winid"
}

[[ "${BASH_SOURCE[0]}" != "${0}" ]] || main $@
