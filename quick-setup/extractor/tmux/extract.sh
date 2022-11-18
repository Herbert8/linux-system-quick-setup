#!/bin/bash

# 此脚本如果在 macOS 上运行，需要安装 rpm 和 rpm2cpio 工具

set -eu

# 获取当前脚本所在位置
BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
readonly BASE_DIR

# 创建临时目录
tmp_dir=$(mktemp -d)
# echo "$tmp_dir"


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

# 获取需要的文件
mv "$tmp_dir/usr/bin" "$OUTPUT_PATH"
mv "$tmp_dir/usr/lib64" "$OUTPUT_PATH"
cp "$BASE_DIR"/misc/* "$OUTPUT_PATH"

# 清理临时文件
rm -rf "$tmp_dir"

# 打包
(
    cd "$OUTPUT_PATH" && gtar --remove-files -zcvf tmux.tar.gz -- *
)

