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

# Function: replace_content
# Description: 使用标准输入的内容替换模板中的占位符
# Parameters:
#   $1 - 模板文件
#   $2 - 占位符
# Returns:
# Example: echo 'My Content' | replace_content template.txt '# INSERT HERE'
replace_content() {
    local template_file=$1
    local placeholder_line=$2

    sed "/$placeholder_line/ {
        r /dev/stdin
        d
    }" "$template_file"
}

get_dialog_version_name() {
    local dialog_pkg=$1
    local ret
    ret=$(tar tf "$dialog_pkg" | head -n1)
    echo "${ret/\//}"
}

main() {

    prepare_dir

    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')

    PROXY_SERVER=http://$(get_ip_addr):8888
    SOURCE_CODE_URL=https://invisible-island.net/datafiles/release/dialog.tar.gz

    local source_pkg=$OUTPUT_PATH/dialog.tar.gz
    echo "Downloading source from [$SOURCE_CODE_URL]"
    cd "$OUTPUT_PATH" && curl -x "$PROXY_SERVER" -fL "$SOURCE_CODE_URL" -o "$source_pkg"

    local name_version
    name_version=$(get_dialog_version_name "$source_pkg")

    # 查找用于构建 dialog 的镜像
    local img_name='dialog-build-env'
    local img_tag='latest'
    # 如果没有找到则进行镜像构建
    if ! docker images | grep "^${img_name}\s*${img_tag}\s*"; then
        docker build --platform 'linux/amd64' \
            --build-arg http_proxy="$PROXY_SERVER" \
            --build-arg https_proxy="$PROXY_SERVER" \
            -t "${img_name}:${img_tag}" - <<EOF
FROM alpine:latest
RUN apk add gcc make musl-dev ncurses-static
EOF
    fi

    # 在 Docker 中编译 dialog
    docker run -i --rm --platform 'linux/amd64' \
        -e http_proxy="$PROXY_SERVER" \
        -e https_proxy="$PROXY_SERVER" \
        -v "$OUTPUT_PATH":/out \
        -w /buildcache "${img_name}:${img_tag}" /bin/sh <<EOF
        mv /out/* ./
        apk add gcc make musl-dev ncurses-static build-base musl-dev ncurses-dev
        tar xvfz *.tar.gz
        cd dialog-*

        LDFLAGS="-static" ./configure
        # LDFLAGS="-static" ./configure \
            # --disable-channel \
            # --disable-gpm \
            # --disable-gtktest \
            # --disable-gui \
            # --disable-netbeans \
            # --disable-nls \
            # --disable-selinux \
            # --disable-smack \
            # --disable-sysmouse \
            # --disable-xsmp \
            # --enable-multibyte \
            # --with-features=huge \
            # --without-x \
            # --with-tlib=ncursesw
        make
        make install
        cp /usr/local/bin/dialog /out/
        strip /usr/local/bin/dialog -o /out/dialog_striped
        cp VERSION /out/
        # cd /out && tar --remove-files -zcvf dialog.tar.gz
        # mkdir -p /out/dialog
        # cp -r /usr/local/* /out/dialog
        # rm -rf /out/vim/lib
        # strip /out/vim/bin/vim
        # chown -R $(id -u):$(id -g) /out/vim
EOF

    local dlg_script_template=$PROJECT_ROOT/misc/dialog.template
    gbase64 <"$OUTPUT_PATH/dialog_striped" |
        replace_content "$dlg_script_template" '<DIALOG_BASE64_DATA>' \
            >"$OUTPUT_PATH/dialog_wrapper.sh"

    (
        cd "$OUTPUT_PATH" &&
            gtar zcvf "${name_version}.tar.gz" *
    )

    exa -Fghl --time-style=long-iso --group-directories-first --color-scale "$OUTPUT_PATH"

    echo -e "Extract '$name_version' completed.\nSource code location: $SOURCE_CODE_URL"

}

main "$@"
