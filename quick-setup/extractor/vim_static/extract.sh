#!/bin/bash

# 参考 vim static 编译
# https://github.com/dtschan/vim-static/blob/master/build.sh

# 此脚本基于 Docker 运行，需要具备 Docker 环境

set -eu


install_package () {
    local package_url=${1:-}
    local folder_name=${2:-tmppkg}
    local tmp_dir
    tmp_dir=$(mktemp -d)
    local target_dir=$OUTPUT_PATH/vim/share/vim/vim90/pack/vendor/start/$folder_name
    mkdir -p "$target_dir"
    if http_proxy="$PROXY_SERVER" https_proxy="$PROXY_SERVER" git clone "$package_url" "$tmp_dir"; then
        cp -vR "$tmp_dir"/* "$target_dir"/
    else
        >&2 echo 'Error: Fetch NERDTree fail.'
    fi
    rm -rf "$tmp_dir"
}

get_latest_tag () {
    local rest_ret
    rest_ret=$(curl -sSLf https://api.github.com/repos/vim/vim/tags)
    echo "$rest_ret" | grep name | head -n1 | sed -nr 's/.*: "(.*)".*/\1/p'
}

main() {

    # 获取当前脚本所在位置
    BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    readonly BASE_DIR

    # 清理输出目录
    OUTPUT_PATH=$BASE_DIR/out
    mkdir -p "$OUTPUT_PATH"
    rm -rf "${OUTPUT_PATH:?}"/*

    # vim 版本
    # VIM_VERSION='v9.0.1670'
    if ! VIM_VERSION=$(get_latest_tag); then
        >&2 echo Get latest tag error.
        exit 1
    fi

    echo "Latest tag: $VIM_VERSION"
    echo

    # 下载的 vim 源码包
    VIM_SRC_ARCHIVE=$VIM_VERSION.tar.gz
    VIM_FULL_TARGET_ARCHIVE=vim_full_$VIM_VERSION.tar
    VIM_LITE_TARGET_ARCHIVE=vim_lite_$VIM_VERSION.tar

    # 下载
    # GitHub 仓库位置：https://github.com/vim/vim
    # 下载位置： https://github.com/vim/vim/archive/版本.tar.gz"
    PROXY_SERVER=http://192.168.50.100:8888
    SOURCE_CODE_URL=https://github.com/vim/vim/archive/${VIM_SRC_ARCHIVE}
    echo "Downloading source from [$SOURCE_CODE_URL]"
    cd "$OUTPUT_PATH" && curl -x "$PROXY_SERVER" -fOL "$SOURCE_CODE_URL"

    # 查找用于构建 vim 的镜像
    local img_name='vim-build-env'
    local img_tag='latest'
    # 如果没有找到则进行镜像构建
    if ! docker images | grep "^${img_name}\s*${img_tag}\s*"; then
        docker build \
        --build-arg http_proxy=$PROXY_SERVER \
        --build-arg https_proxy=$PROXY_SERVER \
        -t "${img_name}:${img_tag}" - << EOF
FROM alpine:latest
RUN apk add gcc make musl-dev ncurses-static
EOF
    fi

    # 在 Docker 中编译 vim
    docker run -i --rm \
        -e http_proxy=$PROXY_SERVER \
        -e https_proxy=$PROXY_SERVER \
        -v "$OUTPUT_PATH":/out \
        -w /vimbuildcache "${img_name}:${img_tag}" /bin/sh <<EOF
        mv /out/* ./
        apk add gcc make musl-dev ncurses-static
        tar xvfz "${VIM_SRC_ARCHIVE}"
        cd vim-*
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
            --with-tlib=ncursesw
        make
        make install
        mkdir -p /out/vim
        cp -r /usr/local/* /out/vim
        rm -rf /out/vim/lib
        strip /out/vim/bin/vim
        chown -R $(id -u):$(id -g) /out/vim
EOF

    # 生成版本信息
    echo "$VIM_VERSION" > "$OUTPUT_PATH/vim/VERSION"

    echo 'Installing NERDTree...'
    echo
    # 安装 NERDTree
    install_package 'https://github.com/preservim/nerdtree.git' 'nerdtree'

    echo 'Packaging...'
    # 打包 =========================================================================
    (cd "$OUTPUT_PATH/vim" && gtar --exclude=.DS_Store -cf "$OUTPUT_PATH/$VIM_FULL_TARGET_ARCHIVE" -- *)
    # 将用于运行的脚本存档
    (cd "$BASE_DIR/misc" && gtar rvf "$OUTPUT_PATH/$VIM_FULL_TARGET_ARCHIVE" -- *)

    # 整理 Lite 版本
    cp "$OUTPUT_PATH/$VIM_FULL_TARGET_ARCHIVE" "$OUTPUT_PATH/$VIM_LITE_TARGET_ARCHIVE"
    gtar --delete 'share/vim/vim90/doc' \
        --delete 'share/vim/vim90/spell' \
        --delete 'share/vim/vim90/tutor' \
        -vf "$OUTPUT_PATH/$VIM_LITE_TARGET_ARCHIVE"

    # 以下内容也可以删掉，但对精简空间影响不大，还会影响插件使用，所以不再删除，放在这里备忘
    #  --delete 'share/vim/vim90/ftplugin' \
    #  --delete 'share/vim/vim90/pack' \
    #  --delete 'share/vim/vim90/compiler' \
    #  --delete 'share/vim/vim90/tools' \
    #  --delete 'share/vim/vim90/print' \
    #  --delete 'share/vim/vim90/plugin' \

    # 压缩
    gzip "$OUTPUT_PATH/$VIM_FULL_TARGET_ARCHIVE"
    gzip "$OUTPUT_PATH/$VIM_LITE_TARGET_ARCHIVE"

    # 清理
    rm -rf "${OUTPUT_PATH:?}"/vim

    echo -e "Extract vim $VIM_VERSION completed.\nSource code location: $SOURCE_CODE_URL"

}

main "$@"

