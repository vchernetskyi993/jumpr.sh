#!/bin/bash

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

    exit 0

    echo "Copying script"
    cp -f \
        $CONFIGS_PATH/jumpr.sh \
        $HOME/.local/bin/jumpr

    echo "Setting daemon service"
    cp -f $CONFIGS_PATH/jumpr-daemon.service $HOME/.config/systemd/user/
    systemctl --user daemon-reload
    systemctl --user enable --now jumpr-daemon.service

    echo "Setting shortcut"
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
    gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/" binding "'<Super>Return'"
    gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/" command "'kitty --class=jumpr -1 --instance-group=jumpr jumpr'"
    gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/" name "'App Switcher'"

    LOGO_DIR=$HOME/.local/share/icons/
    LOGO_FILE=jumpr.png
    if [[ -f $LOGO_DIR/$LOGO_FILE ]]; then
        echo "Logo already exists"
    else
        echo "Downloading custom logo from drive"
        LOCAL_DRIVE=$HOME/GoogleDrive
        mkdir -p $LOCAL_DRIVE
        rclone sync google-drive:/$LOGO_FILE $LOCAL_DRIVE

        mkdir -p $LOGO_DIR
        cp $LOCAL_DRIVE/$LOGO_FILE $LOGO_DIR
    fi

    echo "Creating desktop file"
    cp -f $CONFIGS_PATH/jumpr.desktop $HOME/.local/share/applications
    update-desktop-database || true
}

function uninstall() {
    echo "Uninstalling Jumpr"
}

function verify-dependencies() {
    echo "Verifying dependencies"
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

function fail-msg() {
    local RED='\033[0;31m'
    local NC='\033[0m'
    echo -e "${RED}FAIL:${NC} $1" >&2
}

function ok-msg() {
    local GREEN='\033[0;32m'
    local NC='\033[0m'
    echo -e "${GREEN}OK:${NC} $1"
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
