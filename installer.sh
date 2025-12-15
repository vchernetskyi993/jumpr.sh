#!/bin/bash
set -e

BIN_PATH=$HOME/.local/bin/jumpr
DAEMON_FILE=jumpr-daemon.service
DAEMON_PATH="$HOME"/.config/systemd/user/$DAEMON_FILE
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
LOGO_PATH=$DATA_HOME/icons/jumpr.png
DESKTOP_PATH=$DATA_HOME/applications/jumpr.desktop
SHORTCUT="<Super>Return"

function main() {
    if [[ $# -eq 0 ]]; then
        help >&2
        exit 2
    fi

    case "${1:-}" in
    install)
        shift
        install "$@"
        ;;
    uninstall)
        shift
        uninstall "$@"
        ;;
    -h | --help | help)
        help
        ;;
    *)
        echo "Unknown command: $1" >&2
        help >&2
        exit 2
        ;;
    esac
}

function install() {
    echo "Installing Jumpr"
    BASE_PATH=$(dirname "$0")
    CONFIGS_PATH=$BASE_PATH/installer

    verify-dependencies

    stage "Copying binary"
    copy "$BASE_PATH"/jumpr.sh "$BIN_PATH"

    stage "Setting daemon service"
    copy "$CONFIGS_PATH"/jumpr-daemon.service "$DAEMON_PATH"
    systemctl --user daemon-reload
    systemctl --user enable --now $DAEMON_FILE

    stage "Copying icon"
    copy "$CONFIGS_PATH"/jumpr.png "$LOGO_PATH"

    stage "Creating desktop file"
    copy "$CONFIGS_PATH"/jumpr.desktop "$DESKTOP_PATH"
    update-desktop-database &>/dev/null || true

    set-shortcut
}

function uninstall() {
    echo "Uninstalling Jumpr"

    stage "Removing binary"
    remove "$BIN_PATH"

    stage "Removing daemon"
    remove "$DAEMON_PATH"

    stage "Removing logo"
    remove "$LOGO_PATH"

    stage "Removing desktop file"
    remove "$DESKTOP_PATH"

    BASE_PATH=$(dirname "$0")
    remove-shortcut
}

function verify-dependencies() {
    stage "Verifying dependencies"
    verify-binaries
    verify-versions
    verify-extensions
}

function verify-binaries() {
    bins=(gtk-launch gdbus gsettings gnome-session-quit systemctl fzf jq kitty)
    missing=()
    for bin in "${bins[@]}"; do
        if ! command -v "$bin" >/dev/null 2>&1; then
            missing+=("$bin")
        fi
    done

    if ((${#missing[@]} > 0)); then
        fail-msg "Missing binaries:"
        printf '  - %s\n' "${missing[@]}"
        echo "Please, install those and restart this script"
        exit 1
    fi

    ok-msg "All binaries are present."
}

function verify-versions() {
    declare -A req_map=(
        [fzf]="0.60.3"
        [kitty]="0.42.0"
    )
    local failed=0

    for bin in "${!req_map[@]}"; do
        local expected="${req_map[$bin]}"

        local out
        out="$("$bin" --version)"

        local actual
        actual="$(extract_semver "$out")"

        if [[ -z "$actual" ]]; then
            fail-msg "couldn't parse version for '$bin' from: $out" >&2
            failed=1
            continue
        fi

        if ! ver_gte "$actual" "$expected"; then
            fail-msg "'$bin' version $actual < expected $expected"
            failed=1
        else
            ok-msg "  '$bin' version $actual >= $expected"
        fi
    done

    if [[ $failed -eq 1 ]]; then
        echo "Please, install newer versions and restart this script"
        exit 1
    fi
}

function ver_gte() {
    local a="$1" b="$2"
    [[ "$(printf '%s\n%s\n' "$b" "$a" | sort -V | head -n1)" == "$b" ]]
}

function extract_semver() {
    local text="$1"
    LC_ALL=C grep -Eo '[0-9]+(\.[0-9]+){2}' <<<"$text" | head -n1 || true
}

function verify-extensions() {
    if gdbus call --session \
        --dest org.gnome.Shell \
        --object-path /org/gnome/Shell/Extensions/Windows \
        --method org.gnome.Shell.Extensions.Windows.List \
        >/dev/null 2>&1; then
        ok-msg "window-calls D-Bus interface is present (extension running)."
        return 0
    fi
    fail-msg "window-calls extension not detected (not installed or not running)."
    echo "Please, install and enable extension"
    exit 1
}

function copy() {
    echo "    $1 -> $2"
    mkdir -p "$(dirname "$1")"
    cp -f "$1" "$2"
}

function remove() {
    echo "    Removing $1"
    rm -f "$1"
}

function set-shortcut() {
    stage "Setting shortcut"
    download-shortcut-manager
    "$SHORTCUT_MANAGER" \
        "Jumpr" \
        "kitty --class=jumpr -1 --instance-group=jumpr jumpr" \
        "$SHORTCUT" | sed 's/^/    /'
}

function remove-shortcut() {
    stage "Removing shortcut"
    download-shortcut-manager
    "$SHORTCUT_MANAGER" remove "Jumpr" | sed 's/^/    /'
}

function download-shortcut-manager() {
    SHORTCUT_MANAGER_URL=https://raw.githubusercontent.com/vchernetskyi993/gnome-shortcuts-cli/refs/heads/main/command.sh
    SHORTCUT_MANAGER=$BASE_PATH/gnome-shortcuts.sh
    if [ ! -f "$SHORTCUT_MANAGER" ]; then
        curl -sL \
            $SHORTCUT_MANAGER_URL \
            -o "$SHORTCUT_MANAGER"
        chmod +x "$SHORTCUT_MANAGER"
        echo "    $SHORTCUT_MANAGER_URL -> $SHORTCUT_MANAGER"
    else
        echo "    Using existing shortcut manager script: $SHORTCUT_MANAGER"
    fi
}

function fail-msg() {
    local RED='\033[0;31m'
    local NC='\033[0m'
    echo -e "    ${RED}FAIL:${NC} $1" >&2
}

function ok-msg() {
    local GREEN='\033[0;32m'
    local NC='\033[0m'
    echo -e "    ${GREEN}OK:${NC} $1"
}

function stage() {
    local BLUE='\033[0;34m'
    local NC='\033[0m'
    echo -e "  ${BLUE}$1${NC}"
}

function help() {
    cat <<'EOF'
Usage:
  script.sh install      Install window-calls (or whatever you install)
  script.sh uninstall    Uninstall it
  script.sh -h|--help    Show this help
EOF
}

[[ "${BASH_SOURCE[0]}" != "${0}" ]] || main "$@"
