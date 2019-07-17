#!/bin/bash

set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]}"
if command -v realpath >/dev/null 2>&1; then SCRIPT_PATH="$(realpath "$SCRIPT_PATH")"; fi
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd -P)"

# shellcheck source=../bash/common
. "$SCRIPT_DIR/../bash/common"

assert_is_macos

USAGE="Usage: $(basename "$0") [/path/to/formula_list_file...] [formula...]"

# get a list of all available formulae
AVAILABLE_PACKAGES=($(
    set -euo pipefail
    brew search | sort | uniq
))

# and all currently installed formulae
CURRENT_PACKAGES=($(
    set -euo pipefail
    brew list -1 | sort | uniq
))

# load formulae we consider "safe"
SAFE_PACKAGES=()
MAIN_LIST_FILE="$SCRIPT_DIR/homebrew-formulae"
LIST_FILES=("$MAIN_LIST_FILE")

while [ "$#" -gt "0" ] && [ -f "${1:-}" ]; do

    LIST_FILES+=("$1")
    shift

done

for f in "${LIST_FILES[@]}"; do

    PACKAGES=($(
        set -euo pipefail
        cat "$f" | sort | uniq
    ))

    BAD_PACKAGES=($(comm -23 <(printf '%s\n' "${PACKAGES[@]}") <(printf '%s\n' "${AVAILABLE_PACKAGES[@]}")))

    if [ "${#BAD_PACKAGES[@]}" -gt "0" ]; then

        console_message "Invalid $(single_or_plural "${#BAD_PACKAGES[@]}" formula formulae) found in $f:" "${BAD_PACKAGES[*]}" "$BOLD" "$RED" >&2

        [ "$f" = "$MAIN_LIST_FILE" ] && {
            SAFE_PACKAGES+=($(comm -12 <(printf '%s\n' "${PACKAGES[@]}") <(printf '%s\n' "${AVAILABLE_PACKAGES[@]}")))
            continue
        }

        die "$USAGE"

    fi

    SAFE_PACKAGES+=("${PACKAGES[@]}")

done

if [ "$#" -gt "0" ]; then

    PACKAGES=($(printf '%s\n' "$@" | sort | uniq))
    BAD_PACKAGES=($(comm -23 <(printf '%s\n' "${PACKAGES[@]}") <(printf '%s\n' "${AVAILABLE_PACKAGES[@]}")))

    if [ "${#BAD_PACKAGES[@]}" -gt "0" ]; then

        console_message "Invalid $(single_or_plural "${#BAD_PACKAGES[@]}" formula formulae):" "${BAD_PACKAGES[*]}" "$BOLD" "$RED" >&2
        die "$USAGE"

    fi

    SAFE_PACKAGES+=("${PACKAGES[@]}")

fi

SAFE_PACKAGES=($(printf '%s\n' "${SAFE_PACKAGES[@]}" | sort | uniq))

# remove any formulae that aren't actually installed
SAFE_PACKAGES=($(comm -12 <(printf '%s\n' "${SAFE_PACKAGES[@]}") <(printf '%s\n' "${CURRENT_PACKAGES[@]}")))

# add dependencies
SAFE_PACKAGES+=($(brew deps --union "${SAFE_PACKAGES[@]}"))
SAFE_PACKAGES=($(printf '%s\n' "${SAFE_PACKAGES[@]}" | sort | uniq))

REMOVE_LIST=($(comm -23 <(printf '%s\n' "${CURRENT_PACKAGES[@]}") <(printf '%s\n' "${SAFE_PACKAGES[@]}")))

if [ "${#REMOVE_LIST[@]}" -gt "0" ]; then

    NOUN="$(single_or_plural "${#REMOVE_LIST[@]}" formula formulae)"

    console_message "Found ${#REMOVE_LIST[@]} $NOUN to uninstall:" "" "$BOLD" "$MAGENTA"
    echo "${REMOVE_LIST[@]}" | column

    if get_confirmation "Uninstall the $NOUN listed above?" Y Y; then

        console_message "Uninstalling $NOUN..." "" "$GREEN"
        brew uninstall "${REMOVE_LIST[@]}"

    fi

else

    console_message "No formulae to uninstall" "" "$GREEN"

fi
