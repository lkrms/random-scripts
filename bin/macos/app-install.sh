#!/bin/bash
# shellcheck disable=SC1090

include='' . lk-bash-load.sh || exit

[ "$#" -gt "0" ] && lk_files_exist "$@" || lk_die "Usage: $(basename "$0") [--run] /path/to/file..."

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

                lk_console_item "Running Adobe installer:" "$2" "$LK_BOLD$LK_BLUE"
                maybe_dryrun sudo "$ADOBE_INSTALLER" --mode=silent --deploymentFile="${DEPLOY_FILES[0]}" || EXIT_CODE="$?"

                if [ "$EXIT_CODE" -eq "0" ]; then

                    lk_console_item "Installed successfully:" "$2" "$LK_BOLD$LK_GREEN"
                    return

                else

                    lk_console_item "Error installing (exit code ${LK_BOLD}${EXIT_CODE}${LK_RESET}):" "$2" "$LK_BOLD$LK_RED"
                    lk_die

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

    lk_console_item "Installing package:" "$PACKAGE_NAME" "$LK_BOLD$LK_BLUE"

    maybe_dryrun sudo installer -allowUntrusted -package "$1" -target / || EXIT_CODE="$?"

    if [ "$EXIT_CODE" -eq "0" ]; then

        lk_console_item "Package installed successfully:" "$PACKAGE_NAME" "$LK_BOLD$LK_GREEN"

    else

        lk_console_item "Error installing package (exit code ${LK_BOLD}${EXIT_CODE}${LK_RESET}):" "$PACKAGE_NAME" "$LK_BOLD$LK_RED"
        lk_die

    fi

}

for FILE in "$@"; do

    case "$FILE" in

    *.pkg)

        install_pkg "$FILE"
        ;;

    *.dmg)

        lk_console_item "Mounting:" "$(basename "$FILE")"

        MOUNT="$(hdiutil attach -mountroot "$MOUNT_ROOT" "$FILE")"

        # shellcheck disable=SC2034
        while IFS=$'\t' read -r DEV_NODE CONTENT_HINT MOUNT_POINT; do

            [ -n "$MOUNT_POINT" ] || continue

            install_from_folder "$MOUNT_POINT" "$(basename "$FILE")"

        done < <(echo "$MOUNT")

        ;;

    # *.zip)

    #     lk_console_item "Extracting:" "$FILE"
    #     ;;

    *)

        lk_console_item "File type not supported:" "$FILE" "$LK_BOLD$LK_RED"
        ;;

    esac

done

find "$MOUNT_ROOT" -type d -mindepth 1 -maxdepth 1 -exec hdiutil unmount '{}' \; >/dev/null

rm -Rf "$MOUNT_ROOT" "$ARCHIVE_ROOT"
