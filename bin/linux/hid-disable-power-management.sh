#!/bin/bash
# shellcheck disable=SC1091

include='' . lk-bash-load.sh || exit

shopt -s nullglob

DIRS=("$@")
[ "$#" -gt "0" ] || DIRS=("/sys/bus/usb/drivers/usb")
USAGE="Usage: $(basename "$0") [/path/to/sys/device/root | /path/to/sys/device...]"

DEVICES=()

for d in "${DIRS[@]}"; do

    [ ! -e "$d/power/control" ] || DEVICES+=("$(realpath "$d")")

    if [ -d "$d" ]; then

        IFS=$'\n'
        DEVICES+=($(find -L "$d" -type d ! \( -regextype posix-extended -regex '.*/[0-9]+-[0-9]+(.[0-9]+)*:[0-9]+.[0-9]+' -prune \) -exec test -f '{}/power/control' \; -prune -exec realpath '{}' \; 2>/dev/null))
        unset IFS

    fi

done

[ "${#DEVICES[@]}" -gt "0" ] || lk_die "$USAGE"

IFS=$'\n'
DEVICES=($(printf "%s\n" "${DEVICES[@]}" | sort | uniq))
unset IFS

KERNEL_MANUFACTURER="$(uname -sr)"

for DEVICE in "${DEVICES[@]}"; do

    PRODUCT="${DEVICE#/sys/devices/}"
    CURRENT_STATUS="$(<"$DEVICE/power/control")"

    [ ! -f "$DEVICE/idVendor" ] && [ ! -f "$DEVICE/idProduct" ] || PRODUCT="$(<"$DEVICE/idVendor"):$(<"$DEVICE/idProduct") at $PRODUCT"

    # attempt to get a human-readable product name
    PRODUCT_NAME=()
    [ ! -f "$DEVICE/manufacturer" ] || grep -Fq "$KERNEL_MANUFACTURER" "$DEVICE/manufacturer" || PRODUCT_NAME+=("$(<"$DEVICE/manufacturer")")
    [ ! -f "$DEVICE/product" ] || PRODUCT_NAME+=("$(<"$DEVICE/product")")
    [ "${#PRODUCT_NAME[@]}" -eq "0" ] && PRODUCT="${LK_CYAN}${PRODUCT}${LK_RESET}" || PRODUCT="${LK_BOLD}${LK_CYAN}${PRODUCT_NAME[*]}${LK_RESET}${LK_GREY} (${PRODUCT})${LK_RESET}"

    case "$(basename "$0")" in

    *get*)

        [ "$CURRENT_STATUS" = "on" ] &&
            {
                PM_STATUS="disabled"
                PM_COLOUR="$LK_RED"
            } ||
            {
                PM_STATUS="enabled"
                PM_COLOUR="$LK_GREEN"
            }

        printf "Power management for %s is currently ${LK_BOLD}${PM_COLOUR}%s${LK_RESET}\n" "$PRODUCT" "$PM_STATUS"
        ;;

    *disable*)

        [ "$CURRENT_STATUS" != "on" ] || {
            printf "Power management already disabled for %s\n" "$PRODUCT"
            continue
        }

        if sudo tee "$DEVICE/power/control" >/dev/null <<<"on"; then

            printf "Power management disabled for %s\n" "$PRODUCT"

        else

            printf "Error disabling power management for %s\n" "$PRODUCT"

        fi
        ;;

    *enable*)

        [ "$CURRENT_STATUS" = "on" ] || {
            printf "Power management already enabled for %s\n" "$PRODUCT"
            continue
        }

        if sudo tee "$DEVICE/power/control" >/dev/null <<<"auto"; then

            printf "Power management enabled for %s\n" "$PRODUCT"

        else

            printf "Error enabling power management for %s\n" "$PRODUCT"

        fi
        ;;

    esac

done
