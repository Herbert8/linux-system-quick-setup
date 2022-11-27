#!/bin/bash

set -eu

# 获取当前脚本所在位置
BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
readonly BASE_DIR

# 提取并收集
extract_and_collect () {
    # 软件目录
    local soft_dir
    soft_dir=${1:-}
    # 提取器
    local extractor
    extractor=$soft_dir/extract.sh
    # 判断是否存在
    if [[ -f "$extractor" ]]; then
        bash "$extractor"
        cp "$soft_dir/out"/*.tar.gz "$BASE_DIR/../components/portable_tools/portable_tools/"
    fi
}

# 遍历软件并提取
find "$BASE_DIR" -mindepth 1 -maxdepth 1 -type d -name '*' | while read -r item; do
    extract_and_collect "$item"
done


