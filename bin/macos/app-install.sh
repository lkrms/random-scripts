#!/bin/bash

set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]}"
if command -v realpath >/dev/null 2>&1; then SCRIPT_PATH="$(realpath "$SCRIPT_PATH")"; fi
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd -P)"

# shellcheck source=../../bash/common
. "$SCRIPT_DIR/../../bash/common"

if [ "${1:-}" = "--run" ]; then

    shift

fi

[ "$#" -gt "0" ] && are_files "$@" || die "Usage: $(basename "$0") [--run] /path/to/file..."

DRYRUN_BY_DEFAULT=Y
dryrun_message

MOUNT_ROOT="$HOME/.$(basename "$0").mount"
ARCHIVE_ROOT="$HOME/.$(basename "$0").archive"

mkdir -p "$MOUNT_ROOT" "$ARCHIVE_ROOT"

function install_from_folder() {

    local EXIT_CODE=0 ADOBE_INSTALLER DEPLOY_FILES PKG

    # shellcheck disable=SC2066
    for ADOBE_INSTALLER in "$1/Install.app/Contents/MacOS/Install"; do

        if [ -x "$ADOBE_INSTALLER" ] && [ -d "$1/deploy" ]; then

            DEPLOY_FILES=("$1/deploy/"*.install.xml)

            if [ "${#DEPLOY_FILES[@]}" -eq "1" ] && [ -f "${DEPLOY_FILES[0]}" ]; then

                console_message "Running Adobe installer:" "$2" "$BOLD" "$BLUE"
                maybe_dryrun sudo "$ADOBE_INSTALLER" --mode=silent --deploymentFile="${DEPLOY_FILES[0]}" || EXIT_CODE="$?"

                if [ "$EXIT_CODE" -eq "0" ]; then

                    console_message "Installed successfully:" "$2" "$BOLD" "$GREEN"
                    return

                else

                    console_message "Error installing (exit code ${BOLD}${EXIT_CODE}${RESET}):" "$2" "$BOLD" "$RED"
                    die

                fi

            fi

        fi

    done

    while IFS= read -r -d $'\0' PKG; do

        install_pkg "$PKG"

    done < <(find "$1" -type f -iname '*.pkg' -print0 | sort -z)

}

function install_pkg() {

    local EXIT_CODE=0 PACKAGE_NAME

    PACKAGE_NAME="$(basename "$1")"

    console_message "Installing package:" "$PACKAGE_NAME" "$BOLD" "$BLUE"

    maybe_dryrun sudo installer -allowUntrusted -package "$1" -target / || EXIT_CODE="$?"

    if [ "$EXIT_CODE" -eq "0" ]; then

        console_message "Package installed successfully:" "$PACKAGE_NAME" "$BOLD" "$GREEN"

    else

        console_message "Error installing package (exit code ${BOLD}${EXIT_CODE}${RESET}):" "$PACKAGE_NAME" "$BOLD" "$RED"
        die

    fi

}

for FILE in "$@"; do

    case "$FILE" in

    *.pkg)

        install_pkg "$FILE"
        ;;

    *.dmg)

        console_message "Mounting:" "$(basename "$FILE")" "$CYAN"

        MOUNT="$(hdiutil attach -mountroot "$MOUNT_ROOT" "$FILE")"

        # shellcheck disable=SC2034
        while IFS=$'\t' read -r DEV_NODE CONTENT_HINT MOUNT_POINT; do

            [ -n "$MOUNT_POINT" ] || continue

            install_from_folder "$MOUNT_POINT" "$(basename "$FILE")"

        done < <(echo "$MOUNT")

        ;;

    # *.zip)

    #     console_message "Extracting:" "$FILE" "$CYAN"
    #     ;;

    *)

        console_message "File type not supported:" "$FILE" "$BOLD" "$RED"
        ;;

    esac

done

find "$MOUNT_ROOT" -type d -mindepth 1 -maxdepth 1 -exec hdiutil unmount '{}' \; >/dev/null

rm -Rf "$MOUNT_ROOT" "$ARCHIVE_ROOT"
