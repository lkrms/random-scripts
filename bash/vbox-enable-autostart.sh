#!/bin/bash
# shellcheck disable=SC1090

set -euo pipefail
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}" 2>/dev/null)" || SCRIPT_PATH="$(python -c 'import os,sys;print os.path.realpath(sys.argv[1])' "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

. "$SCRIPT_DIR/common"

[ "$#" -ge "1" ] && [ "$#" -le "3" ] || lk_die "Usage: $(basename "$0") <uuid|vmname> [delay-seconds [acpishutdown|savestate|...]]"

VBoxManage modifyvm "$1" --autostart-enabled on --autostart-delay "${2:-0}" --autostop-type "${3:-acpishutdown}" --defaultfrontend headless || lk_die
