#!/bin/bash
# shellcheck disable=SC1090

set -euo pipefail
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}" 2>/dev/null)" || SCRIPT_PATH="$(python -c 'import os,sys;print os.path.realpath(sys.argv[1])' "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

. "$SCRIPT_DIR/../bash/common"
. "$SCRIPT_DIR/../bash/common-dev"
. "$SCRIPT_DIR/../bash/common-homebrew"

assert_is_macos
assert_not_root

# allow this script to be changed while it's running
{

    offer_sudo_password_bypass

    # install Homebrew if needed
    brew_check

    # don't force a "brew update" -- Homebrew does this often enough automatically
    brew_mark_cache_clean

    # add any missing taps
    brew_check_taps

    brew_queue_formulae "prerequisites" "\
coreutils \
findutils \
gawk \
gnu-sed \
gnu-tar \
grep \
lftp \
msmtp \
node@8 \
pv \
python \
python@2 \
rsync \
s-nail \
telnet \
unison \
wget \
" N

    brew_process_queue

    brew_formula_installed node || {
        PATH="/usr/local/opt/node@8/bin:$PATH" /usr/local/opt/node@8/bin/npm update -g
    }

    brew_queue_formulae "essentials" "\
exiftool \
federico-terzi/espanso/espanso \
imagemagick \
openconnect \
youtube-dl \
"

    brew_queue_casks "desktop essentials" "\
acorn \
balenaetcher \
barrier
firefox \
geekbench \
google-chrome \
handbrake \
iterm2 \
karabiner-elements \
keepassxc \
keepingyouawake \
libreoffice \
makemkv \
mkvtoolnix \
nextcloud \
notable \
pencil \
scribus \
skype \
speedcrunch \
stretchly \
subler \
sublime-text \
the-unarchiver \
transmission \
typora \
vlc \
"

    brew_remove_casks "owncloud"

    brew_queue_casks "proprietary essentials" "\
anylist \
caprine \
microsoft-teams \
rescuetime \
slack \
sonos \
spotify \
twist \
"

    brew_queue_casks "Microsoft Office" "microsoft-office"

    # ghostscript: PDF/PostScript processor
    # mupdf-tools: PDF manipulation tools
    # pandoc: text conversion tool (e.g. Markdown to PDF)
    # poppler: PDF tools like pdfimages
    # pstoedit: converts PDF/PostScript to vector formats
    brew_queue_formulae "PDF tools" "\
ghostscript \
mupdf-tools \
pandoc \
poppler \
pstoedit \
"

    if brew_formula_installed_or_queued "pandoc"; then

        brew_queue_casks "PDF tools" "\
basictex \
" N

    fi

    brew_queue_formulae "OCR tools" "\
ocrmypdf \
tesseract \
tesseract-lang \
"

    brew_queue_casks "photography" "\
adobe-dng-converter \
displaycal \
imageoptim \
"

    brew_queue_formulae "development" "\
ant \
autoconf \
cmake \
gradle \
php@7.2 \
pkg-config \
shellcheck \
shfmt \
"

    brew_remove_formulae "composer"

    brew_queue_casks "development" "\
android-studio \
db-browser-for-sqlite \
dbeaver-community \
hex-fiend \
lingon-x \
postman \
sequel-pro \
sourcetree \
sublime-merge \
visual-studio-code \
"

    brew_queue_formulae "development services" "\
httpd \
mariadb \
mongodb/brew/mongodb-community@4.0 \
"

    brew_queue_casks "PowerShell" "powershell"

    brew_queue_casks "VirtualBox" "\
virtualbox \
virtualbox-extension-pack \
"

    brew_queue_casks "Brother P-touch Editor" "\
brother-p-touch-editor \
brother-p-touch-update-software \
"

    brew_queue_formulae "Db2 dependencies" "\
gcc@7 \
"

    if brew_formula_installed_or_queued "httpd"; then

        lk_console_message "Disabling built-in Apache web server..."
        sudo /usr/sbin/apachectl stop 2>/dev/null || true

    fi

    dev_install_packages Y BREW_INSTALLED

    brew_process_queue

    DEV_JUST_INSTALLED=()
    dev_process_queue DEV_JUST_INSTALLED

    if [ "${#DEV_JUST_INSTALLED[@]}" -gt "0" ]; then

        BREW_INSTALLED+=("${DEV_JUST_INSTALLED[@]}")
        BREW_JUST_INSTALLED+=("${DEV_JUST_INSTALLED[@]}")

    fi

    # TODO (and same on system update):
    # sudo tlmgr update --self && sudo tlmgr install collection-fontsrecommended || die
    # luaotfload-tool --update || die

    dev_apply_system_config

    "$LK_ROOT/bash/dev-system-update.sh"

    exit

}
