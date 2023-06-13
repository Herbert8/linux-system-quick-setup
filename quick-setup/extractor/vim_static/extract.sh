#!/bin/bash

# 参考 vim static 编译
# https://github.com/dtschan/vim-static/blob/master/build.sh


# 此脚本基于 Docker 运行，需要具备 Docker 环境

set -eu

# 获取当前脚本所在位置
BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
readonly BASE_DIR

# 清理输出目录
OUTPUT_PATH=$BASE_DIR/out
mkdir -p "$OUTPUT_PATH"
rm -rf "${OUTPUT_PATH:?}"/*

# vim 版本
VIM_VERSION='v9.0.1572'

# 下载的 vim 源码包
VIM_SRC_ARCHIVE=$VIM_VERSION.tar.gz
VIM_TARGET_ARCHIVE=vim_$VIM_VERSION.tar
VIM_LITE_TARGET_ARCHIVE=vim_lite_$VIM_VERSION.tar

# 下载
# GitHub 仓库位置：https://github.com/vim/vim
# 下载位置： https://github.com/vim/vim/archive/版本.tar.gz"
PROXY_SERVER=http://192.168.50.100:8888
cd "$OUTPUT_PATH" && curl -x "$PROXY_SERVER" -OL "https://github.com/vim/vim/archive/${VIM_SRC_ARCHIVE}"

# 在 Docker 中编译 vim
docker run -i --rm \
    -e http_proxy=$PROXY_SERVER \
    -e https_proxy=$PROXY_SERVER \
    -v "$OUTPUT_PATH":/out \
    -w /vimbuildcache alpine /bin/sh << EOF
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

# 打包 =========================================================================
( cd "$OUTPUT_PATH/vim" && gtar --exclude=.DS_Store -cf "$OUTPUT_PATH/$VIM_TARGET_ARCHIVE" -- * )
# 将用于运行的脚本存档
( cd "$BASE_DIR/misc" && gtar rvf "$OUTPUT_PATH/$VIM_TARGET_ARCHIVE" -- * )

# 整理 Lite 版本
cp "$OUTPUT_PATH/$VIM_TARGET_ARCHIVE" "$OUTPUT_PATH/$VIM_LITE_TARGET_ARCHIVE"
gtar --delete 'share/vim/vim90/doc' \
     --delete 'share/vim/vim90/spell' \
     --delete 'share/vim/vim90/tutor' \
     --delete 'share/vim/vim90/ftplugin' \
     --delete 'share/vim/vim90/pack' \
     --delete 'share/vim/vim90/compiler' \
     --delete 'share/vim/vim90/tools' \
     --delete 'share/vim/vim90/print' \
     --delete 'share/vim/vim90/plugin' \
    -vf "$OUTPUT_PATH/$VIM_LITE_TARGET_ARCHIVE"

# 压缩
gzip "$OUTPUT_PATH/$VIM_TARGET_ARCHIVE"
gzip "$OUTPUT_PATH/$VIM_LITE_TARGET_ARCHIVE"

# 清理
rm -rf "${OUTPUT_PATH:?}"/vim




