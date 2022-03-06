
alias ll='exa -Fghl --time-style=long-iso --group-directories-first --color-scale'
alias lla='exa -aFghl --time-style=long-iso --group-directories-first --color-scale'

mount_rhel_disc () {
    local media_path='/media/rhel-cdrom'
    sudo mkdir -p "$media_path"
    sudo mount /dev/cdrom "$media_path"
    echo "mount: /dev/cdrom -> $media_path"
}

ssproxy () {
    export http_proxy=http://192.168.100.1:8888;
    export https_proxy=$http_proxy;
    export all_proxy=http://192.168.100.1:8889;
}

unproxy () {
    unset http_proxy;
    unset https_proxy;
    unset all_proxy;
}

whichex () {
    readlink -f $(which "$1")
}

