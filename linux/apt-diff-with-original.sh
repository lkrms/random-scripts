#!/bin/bash
# shellcheck disable=SC1090

set -euo pipefail
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}" 2>/dev/null)" || SCRIPT_PATH="$(python -c 'import os,sys;print os.path.realpath(sys.argv[1])' "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

. "$SCRIPT_DIR/../bash/common"
. "$SCRIPT_DIR/../bash/common-apt"

assert_not_root

[ "$#" -ge "1" ] && [ -f "$1" ] || die "Usage: $(basename "$0") </path/to/file> [diff option...]"

FILE_PATH="$(realpath "$1")"

shift

PACKAGES=($(
    dpkg-query -S "$FILE_PATH" 2>/dev/null | sed 's/:.*$//' | sort | uniq
)) && [ "${#PACKAGES[@]}" -gt "0" ] || die "Error: $FILE_PATH doesn't belong to a package"

apt_mark_cache_clean

for p in "${PACKAGES[@]}"; do

    apt_package_installed "$p" || continue

    DOWNLOAD_INFO=($(apt-get ${APT_GET_OPTIONS[@]+"${APT_GET_OPTIONS[@]}"} download --print-uris "$p" 2>/dev/null)) && [ "${#DOWNLOAD_INFO[@]}" -ge "2" ] || {
        lk_console_item "Unable to get archive URI for package:" "$p" "$BOLD$RED"
        continue
    }

    lk_console_item "File appears to belong to package:" "$p"

    # easiest way to eliminate the enclosing quotes
    eval "URL=${DOWNLOAD_INFO[0]}"
    EXTRACT_PATH="${TEMP_DIR}/extract/${DOWNLOAD_INFO[1]}"

    if [ ! -d "$EXTRACT_PATH" ]; then

        mkdir -p "$APT_DEB_PATH" "$(dirname "$EXTRACT_PATH")"
        rm -Rf "$EXTRACT_PATH"

        cd "$APT_DEB_PATH" || die
        lk_console_item "Downloading package archive:" "${WRAP_OFF}${URL}${WRAP}"
        DEB_PATH="$(download_urls "$URL")" || die

        lk_console_message "Extracting package archive to temporary folder"
        dpkg-deb -x "$DEB_PATH" "$EXTRACT_PATH" || {
            rm -Rf "$EXTRACT_PATH"
            die
        }

    else

        lk_console_message "Package archive already available in temporary folder"

    fi

    if [ -e "${EXTRACT_PATH}${FILE_PATH}" ]; then

        lk_console_item "Comparing with original version:" "$FILE_PATH" "$BOLD$MAGENTA"

        if diff "$@" "${EXTRACT_PATH}${FILE_PATH}" "$FILE_PATH"; then

            lk_console_message "No differences found" "$BOLD$GREEN"

        else

            lk_console_item "Original version is available at:" "${EXTRACT_PATH}${FILE_PATH}" "$BOLD"

        fi

        exit

    else

        lk_console_item "Original version of file not found in package:" "$p" "$BOLD$RED"

    fi

done

lk_echo_array "${PACKAGES[@]}" | lk_console_list "Unable to find original version of file. ${#PACKAGES[@]} $(single_or_plural "${#PACKAGES[@]}" package packages) checked:"
