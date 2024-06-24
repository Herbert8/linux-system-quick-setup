#!/bin/bash

# 此脚本基于 Docker 运行，需要具备 Docker 环境

set -eu

get_default_network_device() {
    route get default | grep 'interface: ' | awk ' { print $2 } '
}

get_ip_addr() {
    local network_device
    network_device=$(get_default_network_device)
    network_device=${network_device:-en0}
    ifconfig "$network_device" | sed -nr 's/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p' | head -n1
}

prepare_dir() {
    # 获取当前脚本所在位置
    THIS_SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    readonly THIS_SCRIPT_DIR
    readonly PROJECT_ROOT=$THIS_SCRIPT_DIR

    # 清理输出目录
    OUTPUT_PATH=$THIS_SCRIPT_DIR/out
    readonly OUTPUT_PATH
    mkdir -p "$OUTPUT_PATH"
    rm -rf "${OUTPUT_PATH:?}"/*
}


get_goaccess_name_version() {
    local ver
    ver=$(sed -nr 's/.*goaccess-(.*).tar.gz$/\1/p' <<<"$1")
    echo "goaccess_$ver"
}

main() {

    prepare_dir

    # local timestamp
    # timestamp=$(date '+%Y%m%d_%H%M%S')

    PROXY_SERVER=http://$(get_ip_addr):8888
    SOURCE_CODE_URL=https://tar.goaccess.io/goaccess-1.9.3.tar.gz

    local source_pkg=$OUTPUT_PATH/goaccess.tar.gz
    echo "Downloading source from [$SOURCE_CODE_URL]"
    cd "$OUTPUT_PATH" && curl -x "$PROXY_SERVER" -fL "$SOURCE_CODE_URL" -o "$source_pkg"

    local name_version
    name_version=$(get_goaccess_name_version "$SOURCE_CODE_URL")

    # 查找用于构建 dialog 的镜像
    local img_name='goaccess-build-env'
    local img_tag='latest'
    # 如果没有找到则进行镜像构建
    if ! docker images | grep "^${img_name}\s*${img_tag}\s*"; then
        # 如果对时区有要求，需要 apk add tzdata 安装组件支持
        # 可以通过以下方式修改镜像设置
            # rm -f /etc/localtime && \
            # ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
            # echo "Asia/Shanghai" > /etc/timezone
        # 为了简便，也可以在运行时指定 TZ 环境变量解决
        docker build --platform 'linux/amd64' \
            --build-arg http_proxy="$PROXY_SERVER" \
            --build-arg https_proxy="$PROXY_SERVER" \
            -t "${img_name}:${img_tag}" - <<EOF
FROM alpine:latest
RUN apk add autoconf build-base gcc gettext make musl-dev ncurses-dev ncurses-static libmaxminddb-dev libmaxminddb-static tzdata
EOF
    fi



    # 在 Docker 中编译
    # 注意下，编译时如果需要时间信息，注意指定时区。可以通过 -e TZ=Asia/Shanghai 指定
    # 但同时必须通过 apk add tzdata 安装组件支持。这个在构建镜像时执行
    docker run -i --rm --platform 'linux/amd64' \
        -e TZ=Asia/Shanghai \
        -e http_proxy="$PROXY_SERVER" \
        -e https_proxy="$PROXY_SERVER" \
        -v "$OUTPUT_PATH":/out \
        -w /buildcache "${img_name}:${img_tag}" /bin/sh <<EOF
        mv /out/* ./
        # apk add gcc make musl-dev ncurses-static build-base musl-dev ncurses-dev
        # apk add autopoint base-devel build-essential
        tar xvfz *.tar.gz
        cd goaccess-*

        LDFLAGS="-static" ./configure \
            --disable-channel \
            --disable-gpm \
            --disable-gtktest \
            --disable-gui \
            --disable-netbeans \
            --disable-nls \
            --disable-selinux \
            --disable-smack \
            --disable-sysmouse \
            --disable-xsmp \
            --enable-multibyte \
            --with-features=huge \
            --without-x \
            --with-tlib=ncursesw \
            --enable-utf8 \
            --enable-geoip=mmdb

        make
        make install
        cp /usr/local/bin/goaccess /out/
        strip /usr/local/bin/goaccess -o /out/goaccess_striped
EOF

    exa -Fghl --time-style=long-iso --group-directories-first --color-scale "$OUTPUT_PATH"

    echo -e "Extract '$name_version' completed.\nSource code location: $SOURCE_CODE_URL"

}

main "$@"
