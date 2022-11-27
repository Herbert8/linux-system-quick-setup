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


# 下载的 vim 源码包
VIM_SRC_ARCHIVE=v9.0.0950.tar.gz
VIM_TARGET_ARCHIVE=vim.tar

# 下载
# GitHub 仓库位置：https://github.com/vim/vim
# 下载位置： https://github.com/vim/vim/archive/版本.tar.gz"
cd "$OUTPUT_PATH" && curl -x http://127.0.0.1:8888 -OL "https://github.com/vim/vim/archive/${VIM_SRC_ARCHIVE}"

# 在 Docker 中编译 vim
docker run -i --rm \
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

# 打包
( cd "$OUTPUT_PATH/vim" && gtar --exclude=.DS_Store -cf "$OUTPUT_PATH/$VIM_TARGET_ARCHIVE" -- * )

# 将用于运行的脚本存档
( cd "$BASE_DIR/misc" && gtar rvf "$OUTPUT_PATH/$VIM_TARGET_ARCHIVE" -- * )

# 压缩
gzip "$OUTPUT_PATH/$VIM_TARGET_ARCHIVE"

rm -rf "${OUTPUT_PATH:?}"/vim




