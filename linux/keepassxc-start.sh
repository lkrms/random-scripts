#!/bin/bash
# shellcheck disable=SC1090,SC2016,SC2191

set -euo pipefail
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}" 2>/dev/null)" || SCRIPT_PATH="$(python -c 'import os,sys;print os.path.realpath(sys.argv[1])' "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

. "$SCRIPT_DIR/../bash/common"

assert_not_root

USAGE="Usage: $(basename "$0") </path/to/database> [/path/to/another/database...]"

[ "$#" -gt "0" ] || die "$USAGE"

PASSWORDS=()

case "$PLATFORM" in

mac)

    GET_SECRET=(security find-generic-password -a "$USER" -s "%DATABASE_PATH%" -w)
    SET_SECRET=(security add-generic-password -a "$USER" -s "%DATABASE_PATH%" -l "KeePassXC password for %DATABASE_PATH%" -w)
    KEEPASSXC_PATH="/Applications/KeePassXC.app/Contents/MacOS/KeePassXC"

    [ -x "$KEEPASSXC_PATH" ] || die "$(basename "$0") requires KeePassXC"

    ;;

linux)

    assert_command_exists keepassxc
    assert_command_exists secret-tool

    GET_SECRET=(secret-tool lookup "%DATABASE_PATH%" keepassxc-password)
    SET_SECRET=(secret-tool store --label="KeePassXC password for %DATABASE_PATH%" "%DATABASE_PATH%" keepassxc-password)
    KEEPASSXC_PATH="keepassxc"

    ;;

esac

set +E

for DATABASE_PATH in "$@"; do

    [ -f "$DATABASE_PATH" ] || die "$USAGE"

    NO_PASSWORD=0
    PASSWORD="$("${GET_SECRET[@]//%DATABASE_PATH%/$DATABASE_PATH}" 2>/dev/null)" || NO_PASSWORD=1

    if [ "$NO_PASSWORD" -eq "1" ]; then

        echoc "No password for ${BOLD}${DATABASE_PATH}${RESET} found in keyring. Please provide it now."
        "${SET_SECRET[@]//%DATABASE_PATH%/$DATABASE_PATH}" || die

        PASSWORD="$("${GET_SECRET[@]//%DATABASE_PATH%/$DATABASE_PATH}" 2>/dev/null)" || PASSWORD=

    fi

    PASSWORDS+=("$PASSWORD")

done

IFS=$'\n\n\n'
nohup "$KEEPASSXC_PATH" --pw-stdin "$@" >/dev/null 2>&1 <<<"${PASSWORDS[*]}" &
