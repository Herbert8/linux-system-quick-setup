#!/bin/bash

# 获取当前脚本所在位置
SCRIPT_FILE=$(readlink -f "${BASH_SOURCE[0]}")
BASE_DIR=$(dirname "$SCRIPT_FILE")
readonly SCRIPT_FILE
readonly BASE_DIR

ptmux () {

    local tmux_root=$BASE_DIR

    LD_LIBRARY_PATH=$tmux_root/lib64 "$tmux_root/bin/tmux" -f "$tmux_root/tmux.conf" "$@"

}

ptmux "$@"
