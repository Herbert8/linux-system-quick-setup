#!/bin/bash

# 此脚本基于 Docker 运行，需要具备 Docker 环境

set -eu

# 获取当前脚本所在位置
BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
readonly BASE_DIR

# 清理输出目录
OUTPUT_PATH=$BASE_DIR/out


# 下载的 reptyr 源码包
# https://github.com/nelhage/reptyr/archive/reptyr-0.9.0.tar.gz
REPTYR_SRC_ARCHIVE=reptyr-0.9.0.tar.gz

# 下载
# GitHub 仓库位置：https://github.com/nelhage/reptyr
# 下载位置： https://github.com/nelhage/reptyr/archive/reptyr-版本.tar.gz"
tmp_dir=$(mktemp -d)
cd "$tmp_dir" && curl -x http://127.0.0.1:8888 -OL "https://github.com/nelhage/reptyr/archive/${REPTYR_SRC_ARCHIVE}"


# 在 Docker 中编译 vim
docker run -i --rm \
    -v "$tmp_dir":/src_pkg \
    -v "$OUTPUT_PATH":/out \
    -w /reptyrbuildcache gcc /bin/sh << EOF
        mv /src_pkg/* ./
        tar zxvf "${REPTYR_SRC_ARCHIVE}"
        cd reptyr-reptyr-*
        make
        cp reptyr /out/
EOF

rm -rf "$tmp_dir"
