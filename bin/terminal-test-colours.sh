#!/bin/bash
# shellcheck disable=SC1090

set -euo pipefail
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}" 2>/dev/null)" || SCRIPT_PATH="$(python -c 'import os,sys;print os.path.realpath(sys.argv[1])' "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

. "$SCRIPT_DIR/../bash/common"

for j in $(seq -1 8); do

    for i in $(seq -1 8); do

        if [ "$i" -ne "-1" ] && [ "$i" -eq "$j" ]; then

            continue

        fi

        FG_COLOUR="colour $i"
        BG_COLOUR="colour $j"

        if [ "$i" -eq "-1" ]; then

            FG_COLOUR="colour N"

        else

            lk_safe_tput setaf "$i"

        fi

        if [ "$j" -eq "-1" ]; then

            BG_COLOUR="colour N"

        else

            lk_safe_tput setab "$j"

        fi

        printf 'This is %s on %s. ' "$FG_COLOUR" "$BG_COLOUR"

        lk_safe_tput dim

        printf '%s with dim. ' "$(upper_first "$FG_COLOUR")"

        lk_safe_tput bold

        printf '%s with bold. ' "$(upper_first "$FG_COLOUR")"

        lk_safe_tput sgr0
        [ "$i" -eq "-1" ] || lk_safe_tput setaf "$i"
        [ "$j" -eq "-1" ] || lk_safe_tput setab "$j"

        lk_safe_tput smso

        printf '%s with standout. ' "$(upper_first "$FG_COLOUR")"

        lk_safe_tput bold

        printf '%s with standout and bold.' "$(upper_first "$FG_COLOUR")"

        lk_safe_tput sgr0

        printf '\n'

    done

done
