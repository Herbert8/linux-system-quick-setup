#!/bin/bash

# 此脚本如果在 macOS 上运行，需要安装 rpm 和 rpm2cpio 工具

set -eu

# 获取当前脚本所在位置
BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
readonly BASE_DIR

# 创建临时目录
tmp_dir=$(mktemp -d)
# echo "$tmp_dir"

# 相关 rpm +-*+-*+-*+-*+-*+-*+-*+-*+-*+-*+-*+-*+-*+-*+-*
# libpcap-1.5.3-12.el7.x86_64.rpm
# nmap-6.40-19.el7.x86_64.rpm
# nmap-ncat-6.40-19.el7.x86_64.rpm
# +-*+-*+-*+-*+-*+-*+-*+-*+-*+-*+-*+-*+-*+-*+-*+-*+-*+-*

# 遍历 rpm 包，解压缩到临时目录
for item in "$BASE_DIR"/src_pkg/*.rpm; do
    (
        cd "$tmp_dir"
        rpm2cpio "$item" | cpio -div
    )
done

# 清理输出目录
OUTPUT_PATH=$BASE_DIR/out
mkdir -p "$OUTPUT_PATH"
rm -rf "${OUTPUT_PATH:?}"/*


# 输出的文件
OUTPUT_FILE=$OUTPUT_PATH/nmap.tar
# 获取需要的文件
(
    cd "$tmp_dir/usr" && gtar --exclude=.DS_Store --remove-files -cvf "$OUTPUT_FILE" -- bin/*
    cd "$tmp_dir/usr" && gtar --exclude=.DS_Store --remove-files -rvf "$OUTPUT_FILE" -- lib64/*
    chmod +x "$BASE_DIR/misc/run"
    cd "$BASE_DIR/misc" &&  gtar --exclude=.DS_Store -rvf "$OUTPUT_FILE" -- *
    gzip "$OUTPUT_FILE"
)

# 清理临时文件
rm -rf "$tmp_dir"
