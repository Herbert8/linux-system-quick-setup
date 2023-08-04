#!/bin/bash


# 获取当前脚本所在位置
REAL_SCRIPT_FILE=$(readlink -f "${BASH_SOURCE[0]}")
BASE_DIR=$(dirname "$REAL_SCRIPT_FILE")
readonly REAL_SCRIPT_FILE
readonly BASE_DIR

htop_file=$BASE_DIR/tool/htop
if [[ -f "$htop_file" ]]; then
    chmod +x "$htop_file"
    "$htop_file" -p "$(pgrep -d , redis-server)"
else
    ps -fC redis-server
fi

