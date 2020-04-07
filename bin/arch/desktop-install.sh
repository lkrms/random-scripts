#!/bin/bash
# shellcheck disable=SC1090,SC2015,SC2034,SC2046,SC2174,SC2207

set -euo pipefail
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}" 2>/dev/null)" || SCRIPT_PATH="$(python -c 'import os,sys;print os.path.realpath(sys.argv[1])' "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

. "$SCRIPT_DIR/../../bash/common"

assert_is_desktop
assert_not_root

PAC_INSTALL=()
AUR_INSTALL=()

PAC_KEEP=(
    asciicast2gif
    gnome-python-desktop
    masterpdfeditor
    python2-xlib
    quicktile-git
    ubuntu-keyring
)

PAC_REMOVE=(
    xfce4-screensaver # buggy and insecure
)

# hardware-related
is_virtual || {
    PAC_INSTALL+=(
        guvcview  # webcam utility
        i2c-tools # provides i2c-dev module, required by ddcutil
        linssid   # wireless scanner

        # "general-purpose computing on graphics processing units" (GPGPU)
        # required to run GPU benchmarks, e.g. in Geekbench
        clinfo
        intel-compute-runtime

        # required to use Intel Quick Sync Video in FFmpeg
        intel-media-sdk
    )
    AUR_INSTALL+=(
        ddcutil
        r8152-dkms # common USB / USB-C NIC
    )
}
AUR_INSTALL+=(
    brother-hl5450dn
    brother-hll3230cdw
)

# terminal-based
PAC_INSTALL+=(
    # shells
    asciinema
    bash-completion
    byobu
    ksh
    zsh

    # utilities
    bc
    cdrtools
    jq
    lsb-release
    mediainfo
    p7zip
    pv
    sox
    stow
    unison
    unzip
    vim
    wimlib

    # networking
    bridge-utils
    openconnect
    traceroute
    whois

    # monitoring
    atop
    glances
    htop # 'top' alternative
    iotop
    sysstat

    # network monitoring
    iftop    # shows network traffic by service and host
    iproute2 # (ifstat) dumps network statistics by interface
    nethogs  # groups bandwidth by process ('nettop')
    nload    # shows bandwidth by interface

    # system
    cloud-utils
    hwinfo
    sysfsutils
)

AUR_INSTALL+=(
    #asciicast2gif
    git-filter-repo
    powershell-bin
    #ubuntu-keyring
    vpn-slice
)

# desktop
PAC_INSTALL+=(
    caprine
    catfish
    copyq
    firefox
    firefox-i18n-en-gb
    flameshot
    freerdp
    galculator
    geany
    gimp
    inkscape
    keepassxc
    libreoffice-fresh
    libreoffice-fresh-en-gb
    nextcloud-client
    nomacs # ristretto alternative
    qpdfview
    remmina
    scribus
    speedcrunch
    thunderbird
    thunderbird-i18n-en-gb
    thunderbird-i18n-en-us
    transmission-cli
    transmission-gtk
    trash-cli

    # PDF
    ghostscript  # PDF/PostScript processor
    mupdf-tools  # PDF manipulation tools
    pandoc       # text conversion tool (e.g. Markdown to PDF)
    poppler      # PDF tools like pdfimages
    pstoedit     # converts PDF/PostScript to vector formats
    texlive-core # required for PDF output from pandoc

    # photography
    geeqie
    rapid-photo-downloader

    # search (Recoll)
    antiword            # Word
    aspell-en           # English stemming
    catdoc              # Excel, Powerpoint
    perl-image-exiftool # EXIF metadata
    python-lxml         # spreadsheets
    recoll
    unrtf

    # multimedia - playback
    clementine
    libdvdcss
    libdvdnav
    libvpx
    vlc

    # multimedia - audio
    abcde
    audacity
    beets
    python-eyed3

    # multimedia - video
    ffmpeg
    handbrake
    handbrake-cli
    mkvtoolnix-cli
    mkvtoolnix-gui
    mpv
    rtmpdump
    youtube-dl

    # system
    dconf-editor
    displaycal
    gparted
    guake
    libsecret   # secret-tool
    libva-utils # vainfo
    samba
    seahorse
    syslinux
    vdpauinfo
    x11vnc

    # automation
    sxhkd
    wmctrl
    xautomation
    xclip
    xdotool
    xorg-xev
)

AUR_INSTALL+=(
    espanso
    ghostwriter
    google-chrome
    #masterpdfeditor
    skypeforlinux-stable-bin
    spotify
    teams
    todoist-electron
    trimage
    #ttf-ms-win10
    typora

    # multimedia - video
    makemkv

    # balena-etcher dependency
    electron7-bin

    # system
    balena-etcher
    hfsprogs

    # automation
    devilspie2
    xorg-xkbprint

    # these need to be installed in this order
    #gconf
    #gnome-python
    #gnome-python-desktop #i.e. python2-wnck
    #python2-xlib
    #quicktile-git
)

# development
PAC_INSTALL+=(
    autopep8
    bash-language-server
    dbeaver
    eslint
    python-pylint
    tidy
    ttf-font-awesome
    ttf-ionicons

    # email
    msmtp     # smtp client
    msmtp-mta # sendmail alias for msmtp
    s-nail    # mail and mailx commands

    #
    git
    meld

    #
    jdk11-openjdk
    jre11-openjdk

    #
    nodejs
    npm
    yarn

    #
    composer
    php
    php-gd
    php-imagick
    php-imap
    php-intl
    php-memcache
    php-memcached
    php-sqlite
    xdebug

    #
    mysql-python
    python
    python-dateutil
    python-pip
    python-requests
    python-virtualenv
    python2

    #
    shellcheck
    shfmt

    #
    lua
    lua-penlight

    # platforms
    aws-cli
)

AUR_INSTALL+=(
    postman
    sublime-text-dev
    trickle
    visual-studio-code-bin

    #
    git-cola
    sublime-merge

    #
    php-box
    php-compat-info

    # platforms
    azure-cli
    azure-functions-core-tools-bin
    sfdx-cli
    wp-cli
)

# development services
PAC_INSTALL+=(
    apache
    mariadb
    php-fpm
)

AUR_INSTALL+=(
    mongodb-bin
)

# VMs and containers
PAC_INSTALL+=(
    # libvirt
    dnsmasq
    ebtables
    libvirt
    qemu
    qemu-arch-extra # includes UEFI firmware, among other goodies
    virt-manager

    # docker
    docker
)

{

    ! offer_sudo_password_bypass ||
        {
            lk_console_message "Disabling password-based login as root"
            sudo passwd -l root
        }

    PAC_TO_REMOVE=($(comm -12 <(pacman -Qq | sort | uniq) <(lk_echo_array "${PAC_REMOVE[@]}" | sort | uniq)))
    [ "${#PAC_TO_REMOVE[@]}" -eq "0" ] || {
        lk_console_message "Removing packages"
        sudo pacman -R "${PAC_TO_REMOVE[@]}"
    }

    PAC_TO_MARK_EXPLICIT=($(comm -12 <(pacman -Qdq | sort | uniq) <(lk_echo_array "${PAC_INSTALL[@]}" "${AUR_INSTALL[@]}" ${PAC_KEEP[@]+"${PAC_KEEP[@]}"} | sort | uniq)))
    [ "${#PAC_TO_MARK_EXPLICIT[@]}" -eq "0" ] || {
        lk_console_message "Setting install reasons"
        sudo pacman -D --asexplicit "${PAC_TO_MARK_EXPLICIT[@]}"
    }

    PAC_TO_INSTALL=($(comm -13 <(pacman -Qeq | sort | uniq) <(lk_echo_array "${PAC_INSTALL[@]}" | sort | uniq)))
    [ "${#PAC_TO_INSTALL[@]}" -eq "0" ] || {
        lk_console_message "Installing new packages from repo"
        sudo pacman -Sy "${PAC_TO_INSTALL[@]}"
    }

    ! PAC_TO_PURGE=($(pacman -Qdtq)) ||
        [ "${#PAC_TO_PURGE[@]}" -eq "0" ] ||
        ! get_confirmation "Purge orphaned packages?" ||
        sudo pacman -Rns "${PAC_TO_PURGE[@]}"

    lk_console_message "Upgrading installed packages"
    sudo pacman -Syu

    # otherwise makepkg fails with "unknown public key" errors
    lk_console_message "Checking GPG keys"
    [ -e "$HOME/.gnupg" ] || gpg --list-keys >/dev/null
    [ -e "$HOME/.gnupg/gpg.conf" ] || {
        touch "$HOME/.gnupg/gpg.conf" &&
            chmod 600 "$HOME/.gnupg/gpg.conf"
    }
    [ ! -e "/etc/pacman.d/gnupg/pubring.gpg" ] || {
        lk_apply_setting "$HOME/.gnupg/gpg.conf" "keyring" "/etc/pacman.d/gnupg/pubring.gpg" " "
    }
    GPG_KEYS=(
        194B631AB2DA2888 # devilspie2
        293D771241515FE8 # php-box
        4773BD5E130D1D45 # spotify
        F57D4F59BD3DF454 # sublime
    )
    MISSING_GPG_KEYS=($(comm -13 <(lk_get_gpg_keyids | lk_lower | sort | uniq) <(lk_echo_array "${GPG_KEYS[@]}" | lk_lower | sort | uniq)))
    [ "${#MISSING_GPG_KEYS[@]}" -eq "0" ] || {
        lk_console_message "Importing ${#MISSING_GPG_KEYS[@]} GPG $(lk_maybe_plural "${#MISSING_GPG_KEYS[@]}" key keys)"
        gpg --recv-keys "${GPG_KEYS[@]}"
    }

    AUR_TO_INSTALL=($(comm -13 <(pacman -Qeq | sort | uniq) <(lk_echo_array "${AUR_INSTALL[@]}" | sort | uniq)))
    [ "${#AUR_TO_INSTALL[@]}" -eq "0" ] || {
        lk_console_message "Installing new packages from AUR"
        yay -Sy --aur "${AUR_TO_INSTALL[@]}"
    }

    lk_console_message "Upgrading installed AUR packages"
    yay -Syu --aur

    SUDO_OR_NOT=1 lk_apply_setting "/etc/ssh/sshd_config" "PasswordAuthentication" "no" " " "#" " " &&
        SUDO_OR_NOT=1 lk_apply_setting "/etc/ssh/sshd_config" "AcceptEnv" "LANG LC_*" " " "#" " " &&
        sudo systemctl enable --now sshd || true

    # TODO: configure /etc/ntp.conf with "server ntp.lkrms.org iburst"
    sudo systemctl enable --now ntpd || true

    sudo systemctl enable --now org.cups.cupsd || true

    SUDO_OR_NOT=1 lk_apply_setting "/etc/bluetooth/main.conf" "AutoEnable" "true" "=" "#" &&
        sudo systemctl enable --now bluetooth

    SUDO_OR_NOT=1 lk_apply_setting "/etc/conf.d/libvirt-guests" "ON_SHUTDOWN" "shutdown" "=" "# " &&
        SUDO_OR_NOT=1 lk_apply_setting "/etc/conf.d/libvirt-guests" "SHUTDOWN_TIMEOUT" "300" "=" "# " &&
        sudo usermod --append --groups libvirt "$USER" &&
        sudo systemctl enable --now libvirtd libvirt-guests || true

    sudo usermod --append --groups docker "$USER" &&
        sudo systemctl enable --now docker || true

    { sudo test -d "/var/lib/mysql/mysql" ||
        sudo mariadb-install-db --user="mysql" --basedir="/usr" --datadir="/var/lib/mysql"; } &&
        sudo systemctl enable --now mysqld || true

    SUDO_OR_NOT=1

    for PHP_EXT in bcmath curl gd gettext imap intl mysqli sqlite3 xmlrpc zip; do
        lk_enable_entry "/etc/php/php.ini" "extension=$PHP_EXT" ";"
    done
    lk_apply_setting "/etc/php/php.ini" "memory_limit" "256M" " = " ";" " "
    lk_apply_setting "/etc/php/php.ini" "error_reporting" "E_ALL" " = " ";" " "
    lk_apply_setting "/etc/php/php.ini" "display_errors" "On" " = " ";" " "
    lk_apply_setting "/etc/php/php.ini" "display_startup_errors" "On" " = " ";" " "
    lk_apply_setting "/etc/php/php.ini" "error_log" "syslog" " = " ";" " "
    [ ! -f "/etc/php/conf.d/imagick.ini" ] || lk_enable_entry "/etc/php/conf.d/imagick.ini" "extension=imagick" ";"
    [ ! -f "/etc/php/conf.d/memcache.ini" ] || lk_enable_entry "/etc/php/conf.d/memcache.ini" "extension=memcache.so" ";"
    [ ! -f "/etc/php/conf.d/memcached.ini" ] || lk_enable_entry "/etc/php/conf.d/memcached.ini" "extension=memcached.so" ";"
    [ ! -f "/etc/php/conf.d/xdebug.ini" ] || {
        lk_enable_entry "/etc/php/conf.d/xdebug.ini" "zend_extension=xdebug.so" ";"
        lk_apply_setting "/etc/php/conf.d/xdebug.ini" "xdebug.remote_enable" "on" " = " ";" " "
        lk_apply_setting "/etc/php/conf.d/xdebug.ini" "xdebug.remote_autostart" "on" " = " ";" " "
    }
    sudo systemctl enable --now php-fpm || true

    sudo mkdir -p "/srv/http" &&
        sudo chown -c "$USER:" "/srv/http" &&
        mkdir -p "/srv/http/localhost/html" "/srv/http/127.0.0.1" &&
        { [ -e "/srv/http/127.0.0.1/html" ] || ln -s "../localhost/html" "/srv/http/127.0.0.1/html"; } &&
        lk_safe_symlink "$CONFIG_DIR/httpd-vhost-alias.conf" "/etc/httpd/conf/extra/httpd-vhost-alias.conf" &&
        lk_enable_entry "/etc/httpd/conf/httpd.conf" "Include conf/extra/httpd-vhost-alias.conf" "# " &&
        lk_enable_entry "/etc/httpd/conf/httpd.conf" "LoadModule dir_module modules/mod_dir.so" "# " &&
        lk_enable_entry "/etc/httpd/conf/httpd.conf" "LoadModule headers_module modules/mod_headers.so" "# " &&
        lk_enable_entry "/etc/httpd/conf/httpd.conf" "LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so" "# " &&
        lk_enable_entry "/etc/httpd/conf/httpd.conf" "LoadModule proxy_module modules/mod_proxy.so" "# " &&
        lk_enable_entry "/etc/httpd/conf/httpd.conf" "LoadModule rewrite_module modules/mod_rewrite.so" "# " &&
        lk_enable_entry "/etc/httpd/conf/httpd.conf" "LoadModule vhost_alias_module modules/mod_vhost_alias.so" "# " &&
        sudo systemctl enable --now httpd || true

    unset SUDO_OR_NOT

    ! lk_command_exists vim || lk_safe_symlink "$(command -v vim)" "/usr/local/bin/vi" Y
    ! lk_command_exists xfce4-terminal || lk_safe_symlink "$(command -v xfce4-terminal)" "/usr/local/bin/xterm" Y
    SUDO_OR_NOT=1 lk_install_gnu_commands

    exit

}
